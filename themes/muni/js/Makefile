.PHONY: all

all: email.min.js eprez.min.js

%.min.js: %.js
	yui-compressor $< > $@
