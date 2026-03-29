fx_version 'cerulean'
game 'gta5'

name 'Incident Nexus'
author 'RebelGamer2k20'
description 'Incident Nexus - Standalone Edition'
version '1.4.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/props.lua',
    'client/doors.lua',
    'client/warninglights.lua',
    'client/targeting.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/dispatch.html',
    'ui/screensaver.html'
}

escrow_ignore {
    'config.lua',
    'client/*.lua',
    'server/*.lua',
    'ui/*.html'
}