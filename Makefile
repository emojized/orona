#Sample from https://github.com/pmcdowell-okta/Simple-node-webserver
setup:
	echo "Theo 🇨🇭 submodule init"
	git submodule init
	echo "Theo 🇨🇭 submodule update"
	git submodule update
	echo "Theo 🇨🇭 npm install"
	npm install

build:
	echo "Theo 🇨🇭 build that stuff"
	npm run build
	echo "Theo 🇨🇭 now try to run this fu server"
	git submodule update --init
	npm install
	cake build
	bin/bolo-server


run:
	npm run

orona:
	make setup
	make build
	make run