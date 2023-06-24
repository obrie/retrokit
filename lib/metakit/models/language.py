# Provides helpers to translate between a language name / country to the 
# corresponding language code
class Language:
  NAME_TO_CODE = {
    'Arabic': 'ar',
    'Belgian': 'nl-be',
    'Bulgarian': 'bg',
    'Chinese': 'zh',
    'Croatian': 'hr',
    'Czech': 'cs',
    'Danish': 'da',
    'Dutch': 'nl',
    'English': 'en',
    'Finnish': 'fi',
    'French': 'fr',
    'German': 'de',
    'Greek': 'el',
    'Hungarian': 'hu',
    'Italian': 'it',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Latvian': 'lv',
    'Norwegian': 'no',
    'Polish': 'pl',
    'Portuguese': 'pt',
    'Russian': 'ru',
    'Slovak': 'sk',
    'Spanish': 'es',
    'Swedish': 'sv',
    'Turkish': 'tr',
    'Ukrainian': 'uk',
  }

  CODES = set(NAME_TO_CODE.values())

  # Add extended regional codes
  CODES.update([
    'en-au',
    'en-ca',
    'en-gb',
    'pt-br',
  ])
