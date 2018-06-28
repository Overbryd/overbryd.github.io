.ONESHELL:

all: build

build:
	hugo

publish: build
	cd public
	git add --all
	git commit -m "🤖publish site"
	git push origin master

