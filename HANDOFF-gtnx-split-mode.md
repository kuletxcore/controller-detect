# Handoff: Infinix GT NX controller, split-mode profile

For: KuletxAI. Goal: a separate controller profile that is used **only** when an Infinix GT NX controller is in split mode. It shows button prompts that mix Xbox and Switch conventions.

Combined mode is out of scope. It reports as a normal Xbox pad and the default Xbox profile already works.

Machine-readable data: [`gtnx-split-profile.json`](gtnx-split-profile.json). Every index in this document comes from that file.
Test tool: https://controller.kuletxcore.workers.dev (Split-mode test, Button labeling, Joy-Con view).

## 1. What split mode is

- The controller is two halves that clip onto a phone. In split mode each half connects as its **own Bluetooth gamepad**.
- Per the manual, split mode is turned on in the Infinix app (Controller Settings). The indicator turns **yellow**. The controller goes back to combined mode at power-off or restart.
- Other modes, which this profile must **not** catch:
  - Native: blue indicator, name `GT NX Controller`, normal Xbox.
  - Mapping: green indicator, name `GT NX Controller-T`, touch-mapping mode.

## 2. Detection

Match on the **device name**, never on VID/PID.

| Half | Gamepad id / Android InputDevice name | Regex |
|---|---|---|
| Left | `GT NX Controller-L` | `GT NX Controller-L\|Infinix Controller-L` |
| Right | `GT NX Controller-R` | `GT NX Controller-R\|Infinix Controller-R` |

- Both halves, and combined mode, report vendor `045e` and product `0b13`. Those are Microsoft's Xbox Wireless Controller IDs, which the GT NX spoofs. So VID/PID can't tell the halves apart, or tell the GT NX from a real Xbox pad.
- The on-box manual says `GT NX Controller-*`. An older printing says `Infinix Controller-*`. Match both.
- **Don't key on slot order.** Gamepad index 0/1 swaps between connections. One run had L=0 and R=1, another had R=0 and L=1.
- **Stale name:** right after switching to split mode, the left half can keep the old combined name (`GT NX Controller`, no suffix) until Bluetooth reconnects. If you see exactly one `-R` plus one un-suffixed `GT NX Controller`, treat the un-suffixed one as L. Or tell the user to reconnect.
- Activate the split profile only when an `-L` or `-R` half is present. Each half works alone (one-half play), so don't require both.

## 3. Hardware facts that shape the profile

1. **No analog input in split mode.** Neither half sends any axis values; all 4 axes stay at 0. The left stick comes through as **digital d-pad buttons** (8-way, no magnitude). In combined mode the stick is analog. Don't show analog-only prompts (e.g. "push gently") in split mode.
2. **There's no right stick.** The right half has a touchpad. In split mode it sends random bursts of buttons 12–15. **Ignore 12–15 on `-R`.** Pressing the touchpad in does send a clean **index 11 (R3)**, so the touchpad works as one click button.
3. **Each half reports in "sideways" orientation**, like a Switch Joy-Con held sideways. The left stick's directions are rotated 90°: pushing toward the bumpers reports "D-pad Left". The left d-pad reports as face-button indexes 0–3.
4. **The right half's face buttons don't match their printed letters.** Printed **A sends index 3** (Xbox Y). Printed **Y sends index 0** (Xbox A). B and X match.
5. **Each bumper shares an index with one rail button.** On L, LB and the rail button farther from the pin both send index 4. On R, RB and the far rail button both send index 5. You can't tell them apart in software.
6. Both triggers are analog (`value` 0–1) and report as buttons 6 and 7.
7. Rumble (`dual-rumble`) works on each half separately.

## 4. Input map

"Upright" means the half held as if attached to the phone, bumpers on top. **Prompt glyph** is what to draw for that index. It's the label printed on the hardware or the physical control, not the standard-gamepad name.

### Left half (`-L`)

| Index | Standard name (what software sees) | Physical control (upright) | Prompt glyph | Switch dual role |
|---|---|---|---|---|
| 14 | D-pad Left | Stick up | L-stick ↑ | Left stick up |
| 15 | D-pad Right | Stick down | L-stick ↓ | Left stick down |
| 13 | D-pad Down | Stick left | L-stick ← | Left stick left |
| 12 | D-pad Up | Stick right | L-stick → | Left stick right |
| 10 | L3 | Stick click | L3 | L3 |
| 3 | Y | D-pad up | D-pad ↑ | D-pad up |
| 0 | A | D-pad down | D-pad ↓ | D-pad down |
| 1 | B | D-pad left | D-pad ← | D-pad left |
| 2 | X | D-pad right | D-pad → | D-pad right |
| 4 | LB | LB **and** far rail button | LB | L |
| 6 | LT (analog) | LT | LT | ZL |
| 9 | Start | Green View button | View | Minus (−) |
| 8 | Back | Grey Bluetooth button | Bluetooth | Capture (tap only) |
| 5 | RB | Rail button nearer the metal pin | Rail ● | SL or SR (unverified) |

The d-pad is **not** rotated like the stick. It reports as a face-button diamond mirrored left/right: up=Y, down=A, left=B, right=X. This was the same in all 4 labeling runs, so treat it as the real mapping.

### Right half (`-R`)

| Index | Standard name | Physical control | Prompt glyph | Switch dual role (by position) |
|---|---|---|---|---|
| 3 | Y | Printed **A** (bottom) | A | B |
| 1 | B | Printed **B** (right) | B | A |
| 2 | X | Printed **X** (left) | X | Y |
| 0 | A | Printed **Y** (top) | Y | X |
| 5 | RB | RB **and** far rail button | RB | R |
| 7 | RT (analog) | RT | RT | ZR |
| 9 | Start | Green Menu button | Menu | Plus (+) |
| 8 | Back | Grey Screenshot button | Screenshot | Home |
| 4 | LB | Rail button nearer the metal pin | Rail ● | SL or SR (unverified) |
| 11 | R3 | Touchpad pressed in (click) | Pad click | R3 |
| 12–15 | D-pad | Touchpad noise | (ignore) | none |

## 5. Mixed prompt rules

The hardware has Xbox labels in a Switch-style split shape. The prompts should show both.

1. **Glyph comes from the hardware label.** For `-R` index 3 draw **A**, not Y. For `-L` index 3 draw a **d-pad up arrow**, not Y. Look glyphs up by `(half, index)`, never by standard-gamepad name alone.
2. **Use Xbox shapes for shoulders and system buttons:** LB/LT/RB/RT, View, Menu. Those are what's printed.
3. **Use Switch concepts for the layout:**
   - Show a left or right Joy-Con silhouette so the player knows which half to look at.
   - Call the rail buttons SL/SR-style "rail" buttons.
   - Show Minus/Plus/Capture/Home as the role when a game expects Switch semantics.
4. **Tag every prompt with the half** when both are connected. For example, "L · LB" or "R · A". Both halves use the same index numbers for different things: index 3 is the d-pad up arrow on L and the A button on R.
5. **Shared indexes:** for `-L` index 4 show **LB**, and for `-R` index 5 show **RB**. Mention the rail button only in a controls help screen.
6. **No analog prompts in split mode.** Hide sensitivity sliders, "hold halfway" hints and right-stick prompts. Show a note that this game needs a right stick if it does. R3 actions can still be prompted as "Pad click" on `-R`.
7. **Warnings:** don't map hold actions to the left Bluetooth button. Holding it 3 s starts pairing. Treat the right Screenshot button as possibly also taking a phone screenshot.

## 6. Still unverified

Measured on one unit over 4 labeling runs, Android 10, Chrome 157, Web Gamepad API with the `standard` mapping. Firmware version unknown.

- [x] D-pad left/right on `-L`: left=1, right=2, confirmed in 4 runs.
- [x] Touchpad click on `-R` sends index 11 (R3), confirmed in 3 runs.
- [ ] Which rail button is SL and which is SR on each half, by sideways position.
- [ ] Whether a native Android app sees the same indexes. Expect the same Android keycodes, because Chrome's standard mapping comes from Android's KEYCODE_BUTTON_* events. Not tested in a native app.
- [ ] Whether the right Screenshot button also takes a phone screenshot in split mode.
- [ ] Whether newer firmware changes any of this. Re-run the labeling tool after an update.
