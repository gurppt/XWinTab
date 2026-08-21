# XWinTab compatibility patches for Flash, Animate and libinput tablets

XWinTab d'origine (Graham--M) cible Rebelle. Flash CS6 et Animate exercent des
chemins de code que Rebelle n'utilise pas, tandis que les tablettes libinput
modernes ajoutent des contraintes de découverte tardive. Huit groupes de
correctifs sont conservés ici :

1. **Ordinaux Wintab** — Flash résout les fonctions wintab *par ordinal*, pas par
   nom. Ajout d'un `src/wintab32.def` avec les ordinaux canoniques de la spec
   (WTInfoW@1020, WTOpenW@1021, WTGetW@1061, WTClose@22, WTPacketsGet@23,
   WTPacketsPeek@80, WTEnable@40, WTOverlap@41, WTQueueSizeGet@84, WTQueueSizeSet@85)
   et build avec ce `.def` (au lieu de `--kill-at`).

2. **Acceptation du stylet sans bouton** (`check_device`) — exigeait
   `num_buttons > 0`. Le pen Huion expose 0 bouton sous libinput (ils sont sur le
   PAD). Assoupli : on n'exige que `valuator_info && axes >= 3` ; `nButtons` gardé.

3. **WTInfoW(0,0)** — Flash sonde la présence tablette via `WTInfoW(0,0)` ; était
   "unhandled" -> 0 -> "pas de tablette". Ajout du handler (retourne la taille du
   LOGCONTEXTW si un device est sélectionné).

4. **WTI_DEVICES (capacités)** — Flash interroge `DVC_PKTDATA/CSRDATA/X/Y/NPRESSURE`
   pour activer l'UI de pression ; non gérées. Ajout du bloc `cat==WTI_DEVICES`
   (masque WTPKT + structs AXIS X/Y/NPRESSURE, max de pression depuis le device).

5. **Typo `pkt_peek_itr`** (WTPacketsPeek) — `(PktPeekIterData *) data` (cast sur
   soi-même -> pointeur non initialisé). Crash : lecture à l'adresse 0x8 (membre
   `dst`, offset 8). Corrigé en `(PktPeekIterData *) userData`.

6. **WTPacketsPeek garde NULL** — Flash appelle WTPacketsPeek avec un buffer NULL
   pour *compter* les packets ; `packet_copy` écrivait alors vers 0x0. Crash :
   écriture à l'adresse 0x0. Gardé : `if (data->dst) ...` (comme WTPacketsGet).

7. **Re-bind de contexte dans WTOpen** — Flash ré-ouvre un contexte à chaque
   nouveau document sans jamais appeler WTClose. L'ancien garde `if (g_context.handle
   ...) return NULL` renvoyait NULL -> nouveau doc sans pression. Corrigé : si un
   contexte existe déjà, re-bind sur la nouvelle fenêtre (sous g_lock) et renvoie le
   handle existant. (Symptôme d'origine : la pression disparaissait dès que Flash
   se retrouvait sans aucun document ouvert.)

8. **Huion display-tablet device selection (modern libinput)** — on the Kamvas the
   real stylus is a *libinput tablet-tool sub-device* `"...Pen Pen (0)"` created by the X
   server only on first pen proximity (no udev event); it carries the true `Abs Pressure
   0–2047`. The `"...Pad"` node exposes a *phantom* pressure axis `0–16777215`. Two fixes:
   (a) `check_device`: 2nd-pass token fallback (`g_nameFallback`) if the exact
   `XWINTAB_DEVICE` name isn't found; (b) `setup()` reuses its xcb connection so `Load()`
   is re-callable; (c) `WTOpenW` rescans when no device was selected at first load (pen may
   not have been in proximity yet). Also: `launch.sh` auto-detects the `"(0)"` device and
   exports `XWINTAB_DEVICE`, and the pen must be mapped to its output
   (`xinput map-to-output "HUION Huion Monitor Pen Pen (0)" HDMI-0`). Build 64-bit with
   `build64-def.sh` (winegcc + x86_64-w64-mingw32-gcc against `wintab32.def`).
