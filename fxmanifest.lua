fx_version 'cerulean'
game 'gta5'

author 'Advanced Garage System'
description 'Comprehensive garage system with impounds, spawners, and shared garages'
version '1.0.0'

lua54 'yes'

dependencies {
    'oxmysql',
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua',
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

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**/*'
}

exports {
    'GetPlayerVehicles',
    'AddVehicleToGarage',
    'RemoveVehicleFromGarage',
    'CreateHousingGarage',
    'RemoveHousingGarage'
}

server_exports {
    'GetPlayerVehicles',
    'AddVehicleToGarage',
    'RemoveVehicleFromGarage',
    'ImpoundVehicle',
    'ReleaseVehicle',
    'CreateGarage',
    'DeleteGarage'
}