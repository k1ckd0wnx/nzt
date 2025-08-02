fx_version 'cerulean'
game 'gta5'

author 'FiveM Casino Script'
description 'Premium Online Casino for FD Laptop'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

-- ui_page 'web/dist/index.html' -- Disabled: UI is served through fd_laptop

files {
    'web/dist/**/*',
    'web/dist/assets/**/*',
    'casino-icon.svg',
    'dice.svg',
    'assets/**/*'
}

dependencies {
    'oxmysql',
    'fd_laptop',
    'RxBanking'
}

exports {
    'openApp'
}