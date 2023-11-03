from __future__ import annotations

from romkit.resources.downloader import Downloader

import html
import internetarchive
import json
import questionary
import re
import shlex
import subprocess
import traceback
import urllib.parse
import urllib.request
import waybackpy
from collections import defaultdict
from datetime import date, datetime
from pathlib import Path
from waybackpy import WaybackMachineCDXServerAPI

class ManualFinder:
    def __init__(self, system: BaseSystem) -> None:
        self.system = system
        self.date = None
        self.downloader = Downloader(part_threshold=-1)
        self.downloader.headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64)'}

        # Build a cache of titles to corresponding groups
        #
        # This will be used when we're trying to find out where a manual (that might have
        # a slightly different name) should exist in the database
        self.title_to_groups = defaultdict(set)
        for group in self.database.groups:
            metadata = self.database.get(group)
            self.title_to_groups[group].add(group)

            if 'merge' in metadata:
                for merge_title in metadata['merge']:
                    self.title_to_groups[merge_title].add(group)

            if 'aliases' in metadata:
                for alias_title in metadata['aliases']:
                    self.title_to_groups[alias_title].add(group)

    # The metadata database
    @property
    def database(self) -> Database:
        return self.system.database

    # Path to the internetarchive search archive
    @property
    def internetarchive_path(self) -> Path:
        return self._build_download_path('internetarchive', shared=True)

    # Runs the finder for the given date.
    # 
    # This will start an interactive process in which all of the configured source websites are
    # scraped and new manuals are presented to the user on the command-line to be reviewed and,
    # if applicable, added to the database.
    # 
    # If a date is specified, the user is asking to look for manuals that have been added since
    # the given date.
    def run(self, date: str = None, website_name: str = None) -> None:
        if 'manuals' not in self.system.config or 'websites' not in self.system.config['manuals']:
            # No manual discovery enabled
            return

        if date and date != 'all':
            self.date = datetime.strptime(date, '%Y-%m-%d').date()

        search_all_choice = 'Search across all websites'
        search_per_website_choice = 'Search per website'
        review_method = questionary.select('Website review method:', choices=[
            search_all_choice,
            search_per_website_choice,
        ]).ask()
 
        # Find applicable websites
        websites = []
        for website in self.system.config['manuals']['websites']:
            if website_name and website['name'] != website_name:
                continue
            else:
                websites.append(website)

        review = (review_method == search_per_website_choice)
        all_matches = []
        for website in self.system.config['manuals']['websites']:
            print(f"Searching {website['name']} (source: {website['source']})...")
            if website['source'] == 'internetarchive':
                self.download_internetarchive_index()
                new_matches = self.search_internetarchive(website, review=review)
            else:
                new_matches = self.search_generic_website(website, review=review)

            all_matches.extend(new_matches)

        if review_method == search_all_choice:
            # Review all of the discovered matches by searching per group
            self.review_matches(all_matches)

    # Creates a snapshot of the most recently downloaded sources from each website and
    # promotes it to the "previous" download for the given date.
    #
    # The intention is to use this after all websites have been reviewed so that the
    # next time we review the websites, we can compare it to a more recent snapshot and
    # not rely on the wayback machine.
    def snapshot(self, date: str) -> None:
        if 'manuals' not in self.system.config or 'websites' not in self.system.config['manuals']:
            # No manual discovery enabled
            return

        self.date = datetime.strptime(date, '%Y-%m-%d').date()

        for website in self.system.config['manuals']['websites']:
            url_scheme = urllib.parse.urlparse(website['source']).scheme

            if website['name'] == 'internetarchive' or url_scheme == 'file' or '{year}' in website['source']:
                # No need to snapshot since "current" represents a range
                continue

            current_download_path = self._build_download_path(f"{website['name']}-current", shared=website.get('shared', False), include_date=False)
            if current_download_path.exists():
                previous_download_path = self._build_download_path(f"{website['name']}-previous", shared=website.get('shared', False), include_date=('compare_to' not in website))
                if 'compare_to' in website:
                    print(f'cp -v {shlex.quote(str(current_download_path))} {shlex.quote(str(previous_download_path))}')
                else:
                    print(f'cp -v {shlex.quote(str(current_download_path))} {shlex.quote(str(current_download_path.with_suffix(".snapshot")))}')
                    print(f'mv -v {shlex.quote(str(current_download_path))} {shlex.quote(str(previous_download_path))}')

    # Refreshes the internetarchive content for the "manuals" collection
    def download_internetarchive_index(self) -> None:
        # Only refresh if the path doesn't exist
        path = self.internetarchive_path
        if path.exists():
            return

        # Query internet archive for the relevant manuals
        session = internetarchive.session.ArchiveSession()
        query = 'collection:manuals'
        if self.date:
            query += f' AND addeddate:[{self.date} TO null]'
        search = internetarchive.search.Search(session, query, fields=['identifier', 'description', 'title', 'subject', 'collection'])

        # Write results to file
        with path.open('w') as file:
            for result in search:
                file.write(json.dumps(result) + '\n')

    # Searches for content on a generic, non-internetarchive website
    def search_generic_website(self, website: dict, review: bool = True) -> List[dict]:
        url = website['source']
        url_scheme = urllib.parse.urlparse(url).scheme
        url_has_date = '{year}' in url

        # Interpolate any date templates in the URL.
        # 
        # This is used for websites where you can explicitly specify the range of data to look
        # at (e.g. wikipedia-type websites).
        if self.date:
            download_url = url.format(year=self.date.year, month='{:02d}'.format(self.date.month), day='{:02d}'.format(self.date.day))
        else:
            download_url = url.format(year='', month='', day='')

        # Look up latest content
        current_download_path = self._build_download_path(f"{website['name']}-current", shared=website.get('shared', False), include_date=url_has_date)
        try:
            current_content = self._get_or_download(download_url, current_download_path)
        except Exception as e:
            if website.get('required') == False:
                traceback.print_exc()
                current_content = ''
            else:
                raise e

        # Look up previous content (if a date was specified and the current url doesn't have date
        # ranges built into it).
        # 
        # This is *best effort* -- we'll use internetarchive (or an explicit url) to attempt to compare
        # the current content with what it was at a specific date so we can see if there's anything new
        # to review.  It's not perfect, but it minimizes the amount of review we have to do!
        previous_download_path = self._build_download_path(f"{website['name']}-previous", shared=website.get('shared', False))
        previous_content = ''
        if self.date and not url_has_date and (url_scheme == 'http' or url_scheme == 'https'):
            if 'compare_to' in website:
                # Compare to specific url (date is always ignored)
                previous_download_path = self._build_download_path(f"{website['name']}-previous", shared=website.get('shared', False), include_date=False)
                previous_download_url = website['compare_to']
            elif not previous_download_path.exists():
                # Look up oldest snapshot on archive.org
                try:
                    cdx_api = WaybackMachineCDXServerAPI(url, 'retrokit')
                    nearest_snapshot = cdx_api.near(year=self.date.year, month=self.date.month, day=self.date.day)
                    previous_download_url = nearest_snapshot.archive_url
                except waybackpy.exceptions.NoCDXRecordFound:
                    previous_download_url = None
                    print(f'Could not find snapshot! ({previous_download_path})')
            else:
                previous_download_url = f'file://{previous_download_path}'

            if previous_download_url:
                previous_content = self._get_or_download(previous_download_url, previous_download_path)

        # Find new urls
        previous_matches = self._find_matches(website, previous_content)
        current_matches = self._find_matches(website, current_content)
        new_matches = [m for m in current_matches if m not in previous_matches]

        # Review them
        if review:
            self.review_matches(new_matches)

        return new_matches

    # Searches the internetarchive manuals collection
    def search_internetarchive(self, website: dict, review: bool = True) -> List[dict]:
        # Set defaults
        website['base_href'] = 'https://archive.org/details/'
        website['match'] = '^.*"identifier": "(?P<path>[^"]+)".*"title": "(?P<name>[^"]+)".*$'

        # Find new urls
        content = self.internetarchive_path.read_text()
        matches = self._find_matches(website, content)

        # Review them
        if review:
            self.review_matches(matches)

        return matches

    # Finds urls in the given content that match the website scraping configuration
    def _find_matches(self, website: dict, content: str) -> List[dict]:
        matches = list()

        # Define filters
        # 
        # match regex should include the following capture groups:
        # * path
        # * date (optional)
        match_regex = re.compile(website['match'], re.IGNORECASE | re.MULTILINE)
        filter_include_regex = None
        filter_exclude_regex = None
        if 'filter' in website:
            if 'include' in website['filter']:
                filter_include_regex = re.compile(website['filter']['include'], re.IGNORECASE | re.MULTILINE)

            if 'exclude' in website['filter']:
                filter_exclude_regex = re.compile(website['filter']['exclude'], re.IGNORECASE | re.MULTILINE)

        # Track which urls we've seen
        seen_urls = set()

        for match in re.finditer(match_regex, content):
            line = match.group(0)
            groups = match.groupdict()

            # Apply date range
            if self.date and 'date' in groups:
                match_date = datetime.strptime(groups['date'], '%Y-%m-%d').date()
                if match_date < self.date:
                    continue

            # Apply inclusion filtering
            if filter_include_regex and not re.search(filter_include_regex, line):
                continue

            # Apply exclusion filtering
            if filter_exclude_regex and re.search(filter_exclude_regex, line):
                continue

            # Generate the full url
            path = html.unescape(groups['path'])
            default_base_href = website['source'].rsplit('/', 1)[0] + '/'
            base_href = website.get('base_href', default_base_href)
            url = urllib.parse.urljoin(base_href, path)

            if url not in seen_urls:
                seen_urls.add(url)
                matches.append({
                    'url': url,
                    'name': groups.get('name', '').replace('\n', '').strip(),
                })

        return matches

    # Download the url to the given path
    # 
    # We use urllib.request here in order to avoid being blocked by certain websites.
    def _get_or_download(self, url: str, path: Path) -> None:
        if not path.exists():
            print(f'Downloading {url}...')
            self.downloader.get(url.replace(' ', '%20'), path, force=True)

        content = path.read_text(encoding='utf-8', errors='ignore')
        content = re.sub(r'(https://web\.archive\.org)?/web/[0-9]+/', '', content)
        return content

    # Builds a path to where the given website name should be downloaded.
    # 
    # If being requested for a specific date, then the date will be included
    # in the filename.
    def _build_download_path(self, name: str, include_date: bool = True, shared: bool = False) -> Path:
        base_path = Path(self.system.config['manuals']['finder']['tmpdir'])
        base_path.mkdir(parents=True, exist_ok=True)

        if self.date and include_date:
            filename = f'{name}-{self.date}.out'
        else:
            filename = f'{name}.out'

        if not shared:
            filename = f'{self.system.name}-{filename}'

        return base_path.joinpath(filename)

    # Reviews the given urls with the user on the command-line
    def review_matches(self, matches: Set[dict]) -> None:
        matches.sort(key=lambda m: m['url'])

        # Show the user what we've found
        print(f'Found {len(matches)} urls!\n')
        for index, match in enumerate(matches):
            print(f'{index}: {self._describe_match(match)}')
        print()

        if not matches:
            return

        # Determine how we're reviewing
        search_groups_choice = 'Review by URL (search for a group)'
        search_urls_choice = 'Review by Group (search for url(s))'
        skip_choice = 'Skip'
        review_method = questionary.select('URL review method:', choices=[
            search_groups_choice,
            search_urls_choice,
            skip_choice,
        ]).ask()

        if review_method == search_groups_choice:
            self._review_urls_by_group_search(matches)
        elif review_method == search_urls_choice:
            self._review_groups_by_url_search(matches)
        else:
            return

    # Reviews current database's groups by attempting to search for a keyword used in the urls
    def _review_groups_by_url_search(self, matches: List[dict]) -> None:
        groups = sorted(self.database.groups)

        print(f'Groups:')
        for index, group in enumerate(groups):
            if index % 10 == 0:
                print(f'{index}: {group}')
        print()

        # Determine if we're resuming from a prior execution
        start_index = questionary.text('Start index:', multiline=False, default='0', validate=self._validate_nonnegative_number).ask()
        if not start_index:
            return
        start_index = int(start_index)
        groups = groups[start_index:]

        for index, group in enumerate(groups):
            print(f'\n{start_index+index+1}/{start_index+len(groups)}: {group}')
            self._review_group_by_url_search(matches, group)

    # Reviews current database's groups by attempting to search for a keyword used in the url
    def _review_group_by_url_search(self, matches: List[dict], group: str) -> None:
        self.database.reload()
        metadata = self.database.get(group)

        # Print alternate titles and existing manuals to help assist searching
        if 'merge' in metadata:
            print()
            print(f'Alternate titles:')
            for merge_title in metadata['merge']:
                print(f'- {merge_title}')

        self._print_existing_manuals(group)

        # Keep prompting the user until all relevant urls have been reviewed
        while True:
            # Default search string includes group title and all merge titles
            all_titles = [group] + metadata.get('merge', [])
            search_default = '|'.join([title.replace(' ', '.*') for title in all_titles])

            search_string = questionary.text('URL:', default=search_default).ask()
            if not search_string:
                # No content -- stop looking
                return

            filtered_matches = []

            # Find all groups that have an associated title which matches the
            # regular expression provided by the user
            try:
                filter_regex = re.compile(search_string, re.IGNORECASE)
                for match in matches:
                    if filter_regex.search(f"{match['url']} {match['name']}"):
                        filtered_matches.append(match)
            except re.error:
                pass

            # Confirm the url with the user
            if filtered_matches:
                imported_urls, is_done = self._review_group_by_urls(group, filtered_matches)
                matches = [match for match in matches if match['url'] not in imported_urls]

                if is_done:
                    return
            else:
                search_again_choice = 'Search again'
                custom_choice = 'Enter custom url'
                done_choice = 'Done!'
                next_step = questionary.select('No urls found!', choices=[
                    search_again_choice,
                    custom_choice,
                    done_choice,
                ]).ask()

                if next_step == custom_choice:
                    # Allow the user to enter a custom url
                    self._ask_manual(group, '', show_manuals=False)
                elif next_step == done_choice:
                    return

    # Allow the user to review the given list of URLs for a group
    def _review_group_by_urls(self, group: str, matches: List[dict]) -> Tuple[List[str], bool]:
        search_again_choice = 'Search again'
        custom_choice = 'Enter custom url'
        done_choice = 'Done!'

        imported_urls = []

        while matches:
            url_choices = [{'name': f"{match['url']} ({match['name']})", 'value': match} for match in matches]
            match = questionary.select('Select url:', choices=([search_again_choice] + url_choices + [custom_choice, done_choice])).ask()
            if not match or match == search_again_choice:
                break
            elif match == done_choice:
                return imported_urls, True
            else:
                if match == custom_choice:
                    # User wants to input a custom URL
                    url = ''
                else:
                    url = match['url']

                if self._ask_manual(group, url, show_manuals=False):
                    # Don't prompt for this url a second time
                    if match in matches:
                        imported_urls.append(url)
                        matches.remove(match)

        return imported_urls, False

    # Reviews the given list of URLs by attempting to search for a group that matches
    # a keyword used in the url
    def _review_urls_by_group_search(self, matches: List[dict]) -> None:
        # Determine if we're resuming from a prior execution
        start_index = questionary.text('Start index:', multiline=False, default='0', validate=self._validate_nonnegative_number).ask()
        if not start_index:
            return
        start_index = int(start_index)
        matches = matches[start_index:]

        # Check if we should open the URLs in chrome
        chrome_batch_size = 0
        if questionary.confirm('Open in batches in Chrome?', default=False).ask():
            chrome_batch_size = int(questionary.text('Batch size:', default='50', multiline=False).ask())

        for index, match in enumerate(matches):
            # Open in chrome if requested
            if chrome_batch_size and (index % chrome_batch_size == 0):
                print('Opening urls in Chrome...\n')
                for match_to_open in matches[index:index + chrome_batch_size]:
                    subprocess.run(
                        ['google-chrome', match_to_open['url']],
                        stdout = subprocess.DEVNULL,
                        stderr = subprocess.DEVNULL,
                    )

            # Review the url
            print(f"\n{start_index+index+1}/{start_index+len(matches)}: {self._describe_match(match)}")
            self._review_url_by_group_search(match['url'])

    # Reviews the given URL by attempting to search for a group that matches a
    # keyword used in the url
    def _review_url_by_group_search(self, url: str) -> None:
        # Keep prompting the user until we find a matching group or they stop looking
        while True:
            search_string = questionary.text('Group:').ask()
            if not search_string:
                # No content -- stop looking
                return
            else:
                groups = set()

                # Find all groups that have an associated title which matches the
                # regular expression provided by the user
                try:
                    match_regex = re.compile(search_string, re.IGNORECASE)
                    for title in self.title_to_groups:
                        if match_regex.search(title):
                            groups.update(self.title_to_groups[title])
                except re.error:
                    pass

                # Builds list of choices based on matches groups
                # * We include aliases so it's clear why the group matched.  title_to_groups
                #   above takes that into account
                choices = []
                for group in sorted(groups):
                    description = group
                    aliases = self.database.get(group).get('aliases', []) + self.database.get(group).get('merge', [])
                    if aliases:
                        description = f"{description} ({', '.join(aliases)})"
                    choices.append(questionary.Choice(description, value=group))

                if choices:
                    # Confirm the group with the user
                    group = questionary.select('Select group:', choices=choices).ask()
                    if group:
                        break
                else:
                    print('No groups found!')

        self._ask_manual(group, url)

    # Generates a human-readable, clickable description of the given URL match
    def _describe_match(self, match: dict) -> str:
        description = f"\033]8;;{match['url']}\033\\{match['url']}\033]8;;\033\\"
        if match.get('name'):
            description = f"{description} ({match['name']})"

        return description

    # Prints the existing manuals for the given group
    def _print_existing_manuals(self, group: str) -> None:
        metadata = self.database.get(group)

        # Print existing manuals
        manuals = metadata.get('manuals', [])
        if manuals:
            print('\nExisting manuals:')
            for manual in manuals:
                manual_description = f"{','.join(manual['languages'])}\t\t\033]8;;{manual['url']}\033\\{manual['url']}\033]8;;\033\\"
                if 'name' in manual:
                    manual_description += f" ({manual['name']})"
                print(manual_description)
            print()

    # Prompts the user to provide the manual metadata information for the given group / url
    def _ask_manual(self, group: str, url: str, show_manuals: bool = True) -> bool:
        # In case the user has edited it, we want to make sure we've pulled the latest
        # database content before overwriting it
        self.database.reload()

        if show_manuals:
            self._print_existing_manuals(group)

        while True:
            if not questionary.confirm('Continue?', default=True).ask():
                return False

            # Get manual basics
            download_url = questionary.text('URL:', default=url).ask()
            if not download_url:
                return False
            download_url = urllib.parse.unquote(download_url)
            languages = questionary.text('Languages:', default='en').ask()
            if not languages:
                return False

            # Get manual advanced options
            options = {}
            if questionary.confirm('Advanced options:', default=False).ask():
                pages_option = questionary.text('Pages:').ask()
                if pages_option:
                    options['pages'] = pages_option

                rotate_option = questionary.text('Rotate:', validate=self._validate_nonnegative_number).ask()
                if rotate_option:
                    options['rotate'] = int(rotate_option)

                filter_option = questionary.text('Filter:').ask()
                if filter_option:
                    options['filter'] = filter_option

                format_option = questionary.text('Format:').ask()
                if format_option:
                    options['format'] = format_option

            # Build the manual
            manual = {
                'url': download_url,
                'languages': [language.strip() for language in languages.split(',')],
            }
            if options:
                manual['options'] = options

            print(f'Manual: {manual}')
            if questionary.confirm('Confirm?', default=True).ask():
                metadata = self.database.get(group)
                if 'manuals' in metadata:
                    metadata['manuals'] = [m for m in metadata['manuals'] if m['languages'] != manual['languages']]
                else:
                    metadata['manuals'] = []

                # Save the database immediately so we don't lose progress
                metadata['manuals'].append(manual)
                self.database.save()

                return True

    # questionary validation
    # 
    # Ensure value is a non-negative integer
    def _validate_nonnegative_number(self, number: str):
        try:
            number = int(number)
            if number < 0:
                return 'Must be a non-negative integer'
        except:
            return 'Must be a non-negative integer'

        return True

