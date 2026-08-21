#!/bin/bash
set -e
# Helper winelib 64-bit (accès X via xcb-xinput)
winegcc -I/usr/include/wine/wine/windows -o XWinTabHelper.dll.so -shared -O2 src/XWinTabHelper.c src/XWinTabHelper.dll.spec -lxcb -lxcb-xinput
# wintab32.dll 64-bit AVEC .def (ordinals -> patch #1)
x86_64-w64-mingw32-gcc -shared -O2 -o wintab32.dll src/WinTab.c src/wintab32.def
echo "OK: $(file -b wintab32.dll | cut -c1-30) | $(file -b XWinTabHelper.dll.so | cut -c1-30)"
