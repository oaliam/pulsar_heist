fx_version 'cerulean'
game      'gta5'

name        'Pulsar Heist'
description 'heist, awareness system, guard AI, Pulsar minigames, pulsar core'
author      'OA Liam'
version     '1.0.0'

client_script '@pulsar_core/components/cl_error.lua'
shared_script  '@pulsar_core/core/sh_pulsar.lua'
client_script  '@pulsar_pwnzor/client/check.lua'

shared_scripts { 'config/shared/*.lua' }
client_scripts { 'client/*.lua' }
server_scripts { 'server/*.lua' }

ui_page 'html/awareness.html'
files { 'html/awareness.html' }

lua54 'yes'
