prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	install ".build/release/swifty-poeditor" "$(bindir)/swifty-poeditor"

uninstall:
	rm -rf "$(bindir)/swifty-poeditor"

clean:
	rm -rf .build

.PHONY: build install uninstall clean