fx_version 'cerulean'
lua54 'yes'
game 'gta5'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
  '@es_extended/locale.lua',
  'client/*.lua',
  'config.lua'
}

server_scripts {
  '@es_extended/locale.lua',
  'server/*.lua',
  'config.lua'
}
