# XWinTab compatibility fork for Wine

This fork extends [Graham--M/XWinTab](https://github.com/Graham--M/XWinTab), an
experimental Wintab implementation for Windows applications running through Wine.

The original project remains the upstream source. This repository keeps a separate,
buildable compatibility branch for applications and tablet devices that exercise Wintab
paths not covered by upstream XWinTab. It is not a replacement for Wine's built-in
`wintab32` in every application.

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

The first known-good snapshot containing all eight patch groups is commit
[`7a795f4`](https://github.com/gurppt/XWinTab/commit/7a795f4). It intentionally preserves
the diagnostic logging present in the binaries validated with Animate 2024. Debug cleanup
should be performed separately so the known-good reference remains easy to recover.

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

Example launcher fragment for a 64-bit Wine/Proton application:

```bash
export WINEPREFIX=/path/to/prefix
export WINEDLLOVERRIDES="wintab32=n;${WINEDLLOVERRIDES:-}"
export XWINTAB_DEVICE="$(xinput list --name-only 2>/dev/null \
  | grep -i '^HUION' | grep -F '(0)' | head -1)"
exec wine '/path/to/Application.exe'
```

The tablet device must already expose a real pressure valuator under XInput. Hardware
initialisation (for example `uclogic-probe`) and mapping the pen cursor to a monitor are
separate host-level concerns and are deliberately not installed by this repository.

## Using this fork from application-porting projects

Application-specific repositories should not maintain another edited copy of these source
files. Prefer a tagged release or a pinned commit from this fork, and keep only the
application-specific integration in those repositories:

- Wine/Proton version and prefix architecture;
- location where the 32-bit or 64-bit pair is installed;
- `WINEDLLOVERRIDES` and `XWINTAB_DEVICE` launcher configuration;
- the application/tablet combination that was actually tested.

This keeps the Wintab implementation reusable while avoiding divergent copies in Flash,
Animate, Moho or future porting projects.

## Maintaining the fork

The usual remote layout is:

```text
origin    https://github.com/gurppt/XWinTab.git
upstream  https://github.com/Graham--M/XWinTab.git
```

Check for upstream changes without altering the working tree:

```bash
git fetch upstream
git log --oneline main..upstream/main
```

When upstream has new commits, merge or rebase them on a temporary branch first and rebuild
both architectures before updating `main`:

```bash
git switch -c test-upstream-sync
git merge upstream/main
./build64-def.sh
./build32-def.sh
```

Do not force-sync this fork with upstream: that would discard the compatibility patches.
Generic bug fixes can be proposed upstream independently, while application-specific
behaviour can remain documented and maintained here.

## Provenance and license

The upstream project is Copyright Graham McDonald and licensed under the MIT License.
This fork retains the upstream [LICENSE](LICENSE). It is experimental software without
warranty.
