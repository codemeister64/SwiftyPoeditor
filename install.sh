#!/bin/bash

swift build -c release
cd .build/release
cp -f SwiftyPoeditor /usr/local/bin/SwiftyPoeditor