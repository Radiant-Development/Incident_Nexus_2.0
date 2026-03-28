fx_version 'cerulean'
game 'gta5'

name 'incident-nexus'
author 'RebelGamer2k20'
description 'Incident Nexus - Station Infrastructure & Alert System'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/props.lua'
    'client/targeting.lua'
    'client/doors.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/dispatch.html',
    'ui/screensaver.html',
    'languages/*.json',
    'data/drafts/*.json',
    'data/stations/*.json'
}

escrow_ignore {
    'config.lua',
    'languages/*.json',
    'data/drafts/*.json',
    'data/stations/*.json',
    'ui/*.html'
}