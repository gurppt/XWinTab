# XWinTab compatibility fork for Wine

This fork extends [Graham--M/XWinTab](https://github.com/Graham--M/XWinTab), an
experimental Wintab implementation for Windows applications running through Wine.

The changes were developed while enabling pen pressure in Adobe Flash/Animate with a
Huion display tablet under X11/libinput. Several fixes are application-independent:

- canonical Wintab exports by ordinal;
- support for tablet tools that report no buttons;
- `WTInfoW(0, 0)` and `WTI_DEVICES` capability queries;
- two `WTPacketsPeek` crash fixes;
- context re-binding for applications that reopen Wintab without closing it;
- late device discovery and fallback selection for libinput tablet-tool subdevices.

The exact changes and their original symptoms are documented in [PATCHES.md](PATCHES.md).

## Status

- Adobe Flash Professional CS6 (32-bit): previously validated with patches 1–7.
- Adobe Animate 2024 (64-bit): validated locally with patches 1–8 on a Huion Kamvas.
- Moho 14 is not currently a validation target for this fork: the tested installation uses
  GE-Proton's built-in `wintab32`, not XWinTab.
- X11 only. This implementation talks directly to XInput through XCB and is not a native
  Wayland tablet bridge.

## Build

On Debian/Ubuntu, install the upstream requirements plus the appropriate Wine and MinGW
development packages:

```bash
sudo apt install libxcb-xinput-dev wine64-tools gcc-mingw-w64 file
```

Build the 64-bit pair used by Animate 2024:

```bash
./build64-def.sh
```

Build the 32-bit pair used by Flash CS6 (requires the 32-bit Wine development toolchain):

```bash
./build32-def.sh
```

Both commands produce:

- `wintab32.dll`, the Windows Wintab implementation;
- `XWinTabHelper.dll.so`, the Wine/X11 helper.

Copy both files into the Windows application's directory or the matching Wine-prefix
`system32` directory, then force the native override:

```bash
export WINEDLLOVERRIDES='wintab32=n'
```

For devices whose useful pressure node has an unstable name, select it explicitly before
launching Wine:

```bash
export XWINTAB_DEVICE="$(xinput list --name-only | grep -i '^HUION' | grep -F '(0)' | head -1)"
```

## Provenance and license

The upstream project is Copyright Graham McDonald and licensed under the MIT License.
This fork retains the upstream [LICENSE](LICENSE). It is experimental software without
warranty.
