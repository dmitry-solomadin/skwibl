exports.ENVIRONMENT = process.env.NODE_ENV or 'development'
exports.HOST = if @ENVIRONMENT is 'development' then '0.0.0.0' else 'localhost'
exports.PORT = 3000
exports.SOCKET_PORT = 9000

exports.DOMAIN = if @ENVIRONMENT is 'development' then 'http://localhost' else 'http://skwibl.com'

exports.GOOGLE_CLIENT_ID = '435757431999.apps.googleusercontent.com'
exports.GOOGLE_CLIENT_SECRET = 'IoZpFsfeyBuRvs2Djbut1wSZ'

exports.FACEBOOK_APP_ID = if @ENVIRONMENT is 'development' then '604594816233276' else '513105425381842'
exports.FACEBOOK_APP_SECRET = if @ENVIRONMENT is 'development' then 'ce9a493f9e85d633177ad80041af2ff0' else 'ad4fc590e9e78619bcf076c4cda6bfb3'

exports.LINKEDIN_CONSUMER_KEY = 'two4f1vl4319'
exports.LINKEDIN_CONSUMER_SECRET = 'CN5FSKF3HYDw74Do'

exports.DROPBOX_APP_KEY = 'i2bzqlvifx8i0c8'# Core API Key - 'btskqrr7wnr3k20'
exports.DROPBOX_APP_SECRET = 'cd23he9pnhymnly'

exports.YAHOO_CONSUMER_KEY = 'dj0yJmk9SlR3RUNVNGU4cnlMJmQ9WVdrOWJHOWtORlZ3TnpnbWNHbzlNVEkwTkRBeU16RTJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD1kOQ--'
exports.YAHOO_CONSUMER_SECRET = '5e758be1dfc89d2c53fb90b98299598656f7e4f2'

exports.BEHANCE_API_KEY = 's7cImnmGx7l1Qa4gIFrm91CDph7PvMhP'

exports.SITE_SECRET = 'gohph5aer8Edee&V'
exports.SESSION_KEY = 'sid'
exports.SESSION_DURATION = 7200 # two hours

exports.SMTP_USER = 'noreply@skwibl.com'
exports.SMTP_PASSWORD = 'soo8aeyaXa3U'
exports.SMTP_HOST = 'smtp.gmail.com'
exports.SMTP_SSL = yes
exports.SMTP_NOREPLY = 'noreply@skwibl.com'

exports.MIME = [
    '.jpeg': 'image/jpeg'
    '.jpg': 'image/jpeg'
    '.png': 'image/png'
    '.bmp': 'image/bmp'
    '.svg': 'image/svg+xml'
  ,
    '.3g2': 'video/3gpp2'
    '.3gp': 'video/3gpp'
    '.asf': 'video/x-ms-asf'
    '.avi': 'video/x-msvideo'
    '.m4v': 'video/mp4'
    '.mp4': 'video/mp4'
    '.mov': 'video/quicktime'
    '.wmv': 'video/x-ms-wmv'
]

exports.PASSWORD_LENGTH = 12
exports.PASSWORD_MIN_LENGTH = 6
exports.PASSWORD_EASYTOREMEMBER = no

# exports.CONFIRM_EXPIRE = 604800 # one week

exports.UPLOADS = './uploads'
exports.UPLOADS_TMP = './uploads/tmp'

exports.THUMBNAILS = 'thumbnails'

exports.PROJECT_THUMB_SIZE =
  tiny:
    width: 50
    height: 50
  lsmall:
    width: 175
    height: 175
  rsmall:
    width: 105
    height: 90

exports.DIRECTORY_PERMISION = 0o751 # rwxr-x--x
exports.FILE_PERMISSION = 0o640 # rw-r-----

exports.ACTIONS_BUFFER_SIZE = 50

exports.LOG_FILE_SIZE = 1048576 # 1MB

exports.GC_INTERVAL = 60000 # 1 min
