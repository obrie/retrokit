from __future__ import annotations

import lxml.etree
import re
from pathlib import Path

class LaunchboxDatabase:
    DEFAULT_NAME_PATTERN = re.compile('(?P<name>[^\\/]+)\.[^\\/]*$')

    def __init__(self,
        path: Path,
        name_pattern: re.Pattern = DEFAULT_NAME_PATTERN,
        playlists_dir: Path = None,
    ) -> None:
        self.path = path
        self.name_pattern = name_pattern
        self.playlists_dir = playlists_dir
        self.games_by_id = {}
        self._loaded = False

    # The list of games parsed from the database
    @property
    def games(self) -> List[dict]:
        return list(self.games_by_id.values())

    # Looks up the game associated with the given identifier
    def find(self, id: str) -> Optional[dict]:
        return self.games_by_id.get(id)

    # Loads games from the Launchbox gamelist xml file
    def load(self) -> None:
        if self._loaded:
            return

        doc = lxml.etree.iterparse(str(self.path), tag=('Game', 'AlternateName'))

        # Map game names to their metadata
        for event, element in doc:
            if element.tag == 'Game':
                self._load_game(element)
            else:
                self._load_alternate_name(element)

            element.clear()

        # Load playlists
        if self.playlists_dir:
            for playlist_path in self.playlists_dir.glob('*.xml'):
                self._load_playlist(playlist_path)

        self._loaded = True

    # Parses a <Game> element from the database
    def _load_game(self, element: lxml.etree.ElementBase) -> None:
        application_path = element.find('ApplicationPath').text
        match = self.name_pattern.search(application_path)
        if not match:
            return

        game = {
            'id': element.find('ID').text,
            'name': match['name'],
            'alternate_names': set(),
            'playlists': set(),
        }
        self.games_by_id[game['id']] = game

        # Title
        title_tag = element.find('Title')
        if title_tag is not None and title_tag.text is not None:
            game['title'] = title_tag.text

        # Genres
        genre_tag = element.find('Genre')
        if genre_tag is not None and genre_tag.text is not None:
            genres = [genre.strip() for genre in genre_tag.text.split(';')]
            if genres:
                game['genres'] = genres

        # Rating
        rating_tag = element.find('CommunityStarRating')
        if rating_tag is not None and rating_tag.text is not None:
            rating = round(float(rating_tag.text), 1)
            if rating:
                game['rating'] = rating

        # Players
        play_mode_tag = element.find('PlayMode')
        if play_mode_tag is not None and play_mode_tag.text is not None:
            play_mode = play_mode_tag.text
            if 'Multiplayer' in play_mode or 'Cooperative' in play_mode:
                game['players'] = 2
            else:
                game['players'] = 1

        # Release Year
        release_date = element.find('ReleaseDate')
        if release_date is not None and release_date.text is not None:
            year = int(release_date.text[0:4])
            if 'year' not in game or year <= game['year']:
                game['year'] = year

        # Developer
        developer_tag = element.find('Developer')
        if developer_tag is not None and developer_tag.text is not None and developer_tag.text != 'Unknown':
            game['developers'] = [developer_tag.text]

        # Publisher
        publisher_tag = element.find('Publisher')
        if publisher_tag is not None and publisher_tag.text is not None and publisher_tag.text != 'Unknown':
            game['publishers'] = [publisher_tag.text]

        tags = set()

        # Series
        series_tag = element.find('Series')
        if series_tag is not None and series_tag.text is not None:
            all_series = [series.strip() for series in series_tag.text.split(';')]
            series = [series for series in all_series if 'Playlist' not in series]
            if series:
                game['series'] = series

            playlists = [series.replace('Playlist: ', '') for series in all_series if 'Playlist' in series]
            if playlists:
                tags.update(playlists)

        # Tags
        if tags:
            game['tags'] = list(tags)

    # Parses an <AlternateName> element from the database
    def _load_alternate_name(self, element: lxml.etree.ElementBase) -> None:
        game_id = element.find('GameID').text
        game = self.games_by_id[game_id]

        alternate_name = element.find('Name').text
        if alternate_name != game['name'] and alternate_name != game.get('title'):
            game['alternate_names'].add(alternate_name)

    # Loads the playlist at the given path
    def _load_playlist(self, path: Path) -> None:
        playlist_name = None
        game_ids = set()

        # Identify name of the playlist and list of associated games
        doc = lxml.etree.iterparse(str(path), tag=('Playlist', 'PlaylistGame'))
        for event, element in doc:
            if element.tag == 'Playlist':
                playlist_name = element.find('Name').text
            else:
                game_ids.add(element.find('GameId').text)

            element.clear()

        # Update game metadata
        for game_id in game_ids:
            self.find(game_id)['playlists'].add(playlist_name)
