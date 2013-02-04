
## dynamic server
DYN='app'

## socket server
SOC='server'

## coffee executable
COFFEE='node_modules/iced-coffee-script/bin/coffee'

## uglifyjs executable
UGLIFYJS='node_modules/uglify-js/bin/uglifyjs'

## cleancss executable
CLEANCSS='node_modules/clean-css/bin/cleancss'

## application script name
JS_NAME='./assets/js/skwibl'

## application style name
CSS_NAME='./assets/css/skwibl'

## socket.io script
SOCKETIO='./node_modules/socket.io/node_modules/socket.io-client/dist/socket.io.js'

## coffee dir
COFFEE_DIR='client'

## coffee output
JS_OUTPUT_DIR='assets/js/client'

## uploads dir
UPLOADS='uploads'

## uploads temp dir
UPLOADS_TMP='uploads/tmp'

## patches dir
PATCHES_DIR='patches'

## node modules dir
MODULES_DIR='node_modules'

## external server configurations dir
EXTERNAL='external'

## hetzner IP
IP='88.198.192.88'

## hertzner password
PASSWORD='fuThoh5eipe8'

## node execution command
NODE_CMD='node --nouse-idle-notification --expose-gc'

## coffee execution command
COFFEE_OPT='--nodejs "--nouse-idle-notification" --nodejs "--expose-gc"'

## redis flush command
FLUSH_REDIS_CMD='redis-cli flushall'

## tools file (to uncomment gc)
TOOLS_FILE='./tools/tools.iced'

## socket.io script location
SOCKETIO_SCRIPT='./node_modules/socket.io/node_modules/socket.io-client/dist/socket.io.js'

## usage string
USAGE="Usage: $0 -a -b -c -d -i -p -r -s -u -h \n\n
      -a --dynamic Start dynamic server \n
      -b --build Build the project \n
      -c --clean Clean the project auxiliary files \n
      -d --deploy Deploy the project \n
      -i --init Init the project \n
      -o --connect Connect to the production skwibl service through ssh \n
      -p --product Run skwibl in production mode \n
      -r --reset Reset the project \n
      -s --socket Start socket server \n
      -u --update Update project dependencies \n
      -w --dynamicWatch Watch client files for changes \n\n
      -h --help This prompt \n"
