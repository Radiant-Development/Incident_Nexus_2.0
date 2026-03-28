fx_version 'cerulean'
game 'gta5'

name 'Incident Nexus'
author 'RebelGamer2k20'
description 'Incident Nexus - Standalone Edition'
version '1.0.0'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/dispatch.html',
    'ui/screensaver.html'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/props.lua',
    'client/doors.lua',
    'client/targeting.lua'
}

server_scripts {
    'server/main.lua'
}

escrow_ignore {
    'config.lua',
    'client/*.lua',
    'server/*.lua',
    'ui/*.html'
}