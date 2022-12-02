fx_version 'cerulean'

game 'gta5'
lua54 'yes'

description 'ESX Advanced Garage'

Author 'Human Tree92 | Velociti Entertainment'

version '1.1.5'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/de.lua',
	'locales/en.lua',
	'locales/es.lua',
	'locales/cs.lua',
	'config.lua',
	'config_sv.lua',
	'server/main.lua'
}

shared_scripts {
	'@ox_lib/init.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/de.lua',
	'locales/en.lua',
	'locales/es.lua',
	'locales/cs.lua',
	'config.lua',
	'client/main.lua'
}

dependencies {
	'es_extended'
}
