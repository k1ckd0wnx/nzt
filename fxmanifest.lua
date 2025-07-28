fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Vehicle Spawner Script - A complete FiveM script for spawning vehicles'
version '1.0.0'

-- Client Scripts
client_scripts {
    'client/*.lua'
}

-- Server Scripts
server_scripts {
    'server/*.lua'
}

-- Shared Scripts
shared_scripts {
    'shared/*.lua'
}

-- UI Files
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- Dependencies
dependencies {
    'es_extended' -- Optional: Remove if not using ESX
}