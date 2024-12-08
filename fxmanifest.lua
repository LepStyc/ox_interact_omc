fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'french_fab'
description 'OMC Interact'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_script {
   'client/main.lua'
}

files {
    'config/*.lua'
}

dependencies {
    '/onesync',
    'ox_lib',
    'ox_target',
}
