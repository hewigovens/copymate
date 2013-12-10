#!/bin/sh

git submodule update --init
xctool -project CopyMate.xcodeproj -scheme CopyMate
