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

### Official tutorial (reference)

Infinix's own video: [`docs/infinix-split-mode-tutorial.mp4`](docs/infinix-split-mode-tutorial.mp4) (80 s). Key frames: [`docs/infinix-split-mode-tutorial-frames.jpg`](docs/infinix-split-mode-tutorial-frames.jpg). Narration transcript: [`docs/infinix-split-mode-tutorial-transcript.md`](docs/infinix-split-mode-tutorial-transcript.md).

What it shows:
1. **Switch to split mode:** take the left and right halves off the main body (both charged). In the GT NX Controller Settings app, tap **Split Mode**. The controller **re-pairs as two separate controllers**; tap **Connect** for each half, then **Done**. The yellow indicator flashes, then **stays on** once split mode is active. This re-pair is why the left half can briefly keep its old name.
2. **Play:** hold one half in each hand, or give one half to each player (sideways, Joy-Con style), and follow the in-game controls. Infinix says compatibility varies per game, and the app warns that games without split-mode support can't use it.
3. **Back to combined:** either restart the controller (it restores the last-used mode; the settings page can only restore Native mode), or put both halves back on the main body (the right half goes on with the side marked "X" facing up), tap **Combined Mode**. It reconnects in Native mode; the first time, tap **Connect** and then **Set up my device**.
4. Fine print: split mode is supported on selected Infinix phones only. On first connection the controller defaults to Mapping mode and then remembers the last-used mode. The demo uses a GT 50 Pro.

## 2. Detection

Match on the **device name**, never on VID/PID.

| Half | Gamepad id / Android InputDevice name | Regex |
|---|---|---|
| Left | `GT NX Controller-L` | `GT NX Controller-L\|Infinix Controller-L` |
| Right | `GT NX Controller-R` | `GT NX Controller-R\|Infinix Controller-R` |

- Both halves, and combined mode, report vendor `045e` and product `0b13`. Those are Microsoft's Xbox Wireless Controller IDs, which the GT NX spoofs. So VID/PID can't tell the halves apart, or tell the GT NX from a real Xbox pad.
- The on-box manual says `GT NX Controller-*`. An older printing says `Infinix Controller-*`. Match both.
- **Don't key on slot order.** Gamepad index 0/1 swaps between connections. One run had L=0 and R=1, another had R=0 and L=1.
- **Stale name** (seen in early runs; after a reconnect the left half reported `GT NX Controller-L` correctly): right after switching to split mode, the left half can keep the old combined name (`GT NX Controller`, no suffix) until Bluetooth reconnects. If you see exactly one `-R` plus one un-suffixed `GT NX Controller`, treat the un-suffixed one as L. Or tell the user to reconnect.
- Activate the split profile only when an `-L` or `-R` half is present. Each half works alone (one-half play), so don't require both.

## 3. Hardware facts that shape the profile

1. **Hold each half sideways.** This is how the Infinix app shows split mode: each half held horizontally, with the rail (SL/SR) along the top. The left half has the stick on the left and the d-pad on the right. The right half has the face buttons on the left and the touchpad on the right. Everything below uses this grip. Upright is kept only as a reference column.
2. **Each half is a complete controller, and both use the same indexes for the same roles.** The left d-pad and the right face buttons are the same face buttons. The left stick and the touchpad are the same stick. Bind by role, and either half works for any player.
3. **Directions arrive unrotated in the sideways grip.** Stick or touchpad up sends D-pad Up (12), down sends 13, left sends 14 and right sends 15. Both are **digital**: all 4 axes stay at 0, so there is no analog movement or camera.
4. **Face buttons follow the Switch sideways Joy-Con layout by standard index.** A (0) is on the right, B (1) on the bottom, X (2) on top and Y (3) on the left, on both halves. A game that binds "confirm" to A (0) gets the right-hand button of the cluster. The right half's printed letters don't match: printed Y sends A, and printed A sends Y.
5. **SL and SR are indexes 4 and 5 on both halves.** They arrive as LB and RB. That's intended, but **prompt them as SL / SR**. The far-edge bumper sends the same index: LB = SL on the left half, RB = SR on the right. Software can't tell them apart.
6. **Stick press:** 10 (L3) on the left half and 11 (R3) on the right (the touchpad pressed in). Treat both as "stick press". When the touchpad is pressed in, the edge under the finger fires 30–100 ms first, so cancel any 12–15 press that started in the last 150 ms when 11 goes down. Don't make the edges wait before counting: taps under ~120 ms were being lost.
7. **System buttons:** both green buttons send 9 (Menu/Start), so either half can open a menu. Both grey buttons send 8: Bluetooth on the left half (holding it 3 s starts pairing) and Screenshot on the right (may also take a phone screenshot).
8. **Triggers:** LT (6) only on the left half and RT (7) only on the right. Both are analog, 0–1, and on the far edge, so they're awkward in the sideways grip.
9. Rumble (`dual-rumble`) works on each half separately.

## 4. Input map (sideways grip)

**Prompt** is what to draw. It's the label on the hardware: d-pad arrows point the way they face in the sideways grip, and SL/SR are shown for 4 and 5. The same data is in the JSON: `roles`, plus `role`, `sideways` and `glyph` on every control. The old upright glyph is kept as `uprightGlyph`.

### Shared roles: the same on both halves

| Role | Prompt | Left half: control | L index | Right half: control | R index | Standard name |
|---|---|---|---|---|---|---|
| Direction up | Up | stick pushed up | 12 | touchpad, up edge | 12 | D-pad Up |
| Direction down | Down | stick pushed down | 13 | touchpad, down edge | 13 | D-pad Down |
| Direction left | Left | stick pushed left | 14 | touchpad, left edge | 14 | D-pad Left |
| Direction right | Right | stick pushed right | 15 | touchpad, right edge | 15 | D-pad Right |
| Face button, right (A: confirm) | A | right button of the d-pad | 0 | right face button (printed Y) | 0 | A |
| Face button, bottom (B: back) | B | bottom button of the d-pad | 1 | bottom face button (printed B) | 1 | B |
| Face button, top (X) | X | top button of the d-pad | 2 | top face button (printed X) | 2 | X |
| Face button, left (Y) | Y | left button of the d-pad | 3 | left face button (printed A) | 3 | Y |
| SL | SL | LB bumper, on the far edge (same input as SL) **/** left rail button (SL) | 4 | left rail button (SL) | 4 | LB |
| SR | SR | right rail button (SR) | 5 | RB bumper, on the far edge (same input as SR) **/** right rail button (SR) | 5 | RB |
| Stick press | Stick press | stick pressed in | 10 | touchpad pressed in | 11 | L3 / R3 |
| Menu | − / + | green View button | 9 | green Menu button | 9 | Menu/Start |
| Capture / Home | Capture / Home | grey Bluetooth button | 8 | grey Screenshot button | 8 | View/Back |
| Trigger | ZL / ZR | LT, on the far edge | 6 | RT, on the far edge | 7 | LT / RT |

### Full index lookup (0–17)

#### Left half (`-L`)

| Index | Standard name | Android input | Role | Control (sideways grip) | Prompt glyph | Upright (reference) |
|---|---|---|---|---|---|---|
| 0 | A | `KEYCODE_BUTTON_A` | Face button, right (A: confirm) | right button of the d-pad | ▶ | d-pad down |
| 1 | B | `KEYCODE_BUTTON_B` | Face button, bottom (B: back) | bottom button of the d-pad | ▼ | d-pad left |
| 2 | X | `KEYCODE_BUTTON_X` | Face button, top (X) | top button of the d-pad | ▲ | d-pad right |
| 3 | Y | `KEYCODE_BUTTON_Y` | Face button, left (Y) | left button of the d-pad | ◀ | d-pad up |
| 4 | LB | `KEYCODE_BUTTON_L1` | SL | LB bumper, on the far edge (same input as SL) **/** left rail button (SL) | SL **/** SL | left bumper **/** rail button farther from the pin |
| 5 | RB | `KEYCODE_BUTTON_R1` | SR | right rail button (SR) | SR | rail button nearer the metal pin |
| 6 | LT | `AXIS_LTRIGGER` | Trigger | LT, on the far edge | LT | left trigger |
| 7 | RT | `AXIS_RTRIGGER` | — | never fires on this half | — | — |
| 8 | Back/View | `KEYCODE_BUTTON_SELECT` | Capture / Home | grey Bluetooth button | Bluetooth | grey Bluetooth button |
| 9 | Start/Menu | `KEYCODE_BUTTON_START` | Menu | green View button | View (−) | green button |
| 10 | L3 | `KEYCODE_BUTTON_THUMBL` | Stick press | stick pressed in | Stick press | stick click |
| 11 | R3 | `KEYCODE_BUTTON_THUMBR` | — | never fires on this half | — | — |
| 12 | D-pad Up | `KEYCODE_DPAD_UP` | Direction up | stick pushed up | Stick ↑ | stick right |
| 13 | D-pad Down | `KEYCODE_DPAD_DOWN` | Direction down | stick pushed down | Stick ↓ | stick left |
| 14 | D-pad Left | `KEYCODE_DPAD_LEFT` | Direction left | stick pushed left | Stick ← | stick up |
| 15 | D-pad Right | `KEYCODE_DPAD_RIGHT` | Direction right | stick pushed right | Stick → | stick down |
| 16 | Home/Guide | `KEYCODE_BUTTON_MODE` | — | never fires on this half | — | — |
| 17 | (extra) | `none` | — | never fires on this half | — | — |

#### Right half (`-R`)

| Index | Standard name | Android input | Role | Control (sideways grip) | Prompt glyph | Upright (reference) |
|---|---|---|---|---|---|---|
| 0 | A | `KEYCODE_BUTTON_A` | Face button, right (A: confirm) | right face button (printed Y) | Y | printed Y (top) |
| 1 | B | `KEYCODE_BUTTON_B` | Face button, bottom (B: back) | bottom face button (printed B) | B | printed B (right) |
| 2 | X | `KEYCODE_BUTTON_X` | Face button, top (X) | top face button (printed X) | X | printed X (left) |
| 3 | Y | `KEYCODE_BUTTON_Y` | Face button, left (Y) | left face button (printed A) | A | printed A (bottom) |
| 4 | LB | `KEYCODE_BUTTON_L1` | SL | left rail button (SL) | SL | rail button nearer the metal pin |
| 5 | RB | `KEYCODE_BUTTON_R1` | SR | RB bumper, on the far edge (same input as SR) **/** right rail button (SR) | SR **/** SR | right bumper **/** rail button farther from the pin |
| 6 | LT | `AXIS_LTRIGGER` | — | never fires on this half | — | — |
| 7 | RT | `AXIS_RTRIGGER` | Trigger | RT, on the far edge | RT | right trigger |
| 8 | Back/View | `KEYCODE_BUTTON_SELECT` | Capture / Home | grey Screenshot button | Screenshot | grey button |
| 9 | Start/Menu | `KEYCODE_BUTTON_START` | Menu | green Menu button | Menu (+) | green button |
| 10 | L3 | `KEYCODE_BUTTON_THUMBL` | — | never fires on this half | — | — |
| 11 | R3 | `KEYCODE_BUTTON_THUMBR` | Stick press | touchpad pressed in | Pad press | press the touchpad in |
| 12 | D-pad Up | `KEYCODE_DPAD_UP` | Direction up | touchpad, up edge | Pad ↑ | swipe touchpad left |
| 13 | D-pad Down | `KEYCODE_DPAD_DOWN` | Direction down | touchpad, down edge | Pad ↓ | swipe touchpad right |
| 14 | D-pad Left | `KEYCODE_DPAD_LEFT` | Direction left | touchpad, left edge | Pad ← | swipe touchpad down |
| 15 | D-pad Right | `KEYCODE_DPAD_RIGHT` | Direction right | touchpad, right edge | Pad → | swipe touchpad up |
| 16 | Home/Guide | `KEYCODE_BUTTON_MODE` | — | never fires on this half | — | — |
| 17 | (extra) | `none` | — | never fires on this half | — | — |

### Each half as a standalone Xbox controller (no GT NX profile)

This is what a game sees if it skips the GT NX profile and treats each half as its own Xbox controller. Both halves identify as Microsoft Xbox Wireless Controllers (`045e:0b13`), so any game will do this unless it matches the `-L`/`-R` names. In the sideways grip most of it already works. What doesn't:
- There are no analog sticks; movement only works if the game also accepts the D-pad.
- The face buttons sit in Switch positions, so Xbox prompts point at the wrong button. The right half's printed A and Y are also swapped.
- The grey button arrives as View.
- Which half becomes player 1 changes between connections.

#### Left half (`-L`)

| Control (sideways grip) | Index | A game sees (Xbox) | OK? | Note |
|---|---|---|---|---|
| right button of the d-pad | 0 | A | ❌ | Switch sideways position (A right, B bottom, X top, Y left), not Xbox (A bottom, B right, X left, Y top) |
| bottom button of the d-pad | 1 | B | ❌ | Switch sideways position (A right, B bottom, X top, Y left), not Xbox (A bottom, B right, X left, Y top) |
| top button of the d-pad | 2 | X | ❌ | Switch sideways position (A right, B bottom, X top, Y left), not Xbox (A bottom, B right, X left, Y top) |
| left button of the d-pad | 3 | Y | ❌ | Switch sideways position (A right, B bottom, X top, Y left), not Xbox (A bottom, B right, X left, Y top) |
| grey Bluetooth button | 8 | View/Back | ❌ | arrives as View/Back; holding it starts pairing |
| LB bumper, on the far edge (same input as SL) | 4 | LB | ✅ | SL/SR arrive as LB (intended); show SL/SR prompts |
| left rail button (SL) | 4 | LB | ✅ | SL/SR arrive as LB (intended); show SL/SR prompts |
| right rail button (SR) | 5 | RB | ✅ | SL/SR arrive as RB (intended); show SL/SR prompts |
| LT, on the far edge | 6 | LT | ✅ | LT only on the left half, RT only on the right |
| green View button | 9 | Menu/Start | ✅ | both halves send Menu/Start (9) |
| stick pressed in | 10 | L3 | ✅ | L3 on the left half, R3 on the right half; treat both as "stick press" |
| stick pushed up | 12 | D-pad Up | ✅ | correct direction, but as a digital D-pad, never an analog stick |
| stick pushed down | 13 | D-pad Down | ✅ | correct direction, but as a digital D-pad, never an analog stick |
| stick pushed left | 14 | D-pad Left | ✅ | correct direction, but as a digital D-pad, never an analog stick |
| stick pushed right | 15 | D-pad Right | ✅ | correct direction, but as a digital D-pad, never an analog stick |

#### Right half (`-R`)

| Control (sideways grip) | Index | A game sees (Xbox) | OK? | Note |
|---|---|---|---|---|
| right face button (printed Y) | 0 | A | ❌ | Switch sideways position (A right, B bottom, X top, Y left), not Xbox (A bottom, B right, X left, Y top); printed Y sends A |
| bottom face button (printed B) | 1 | B | ❌ | Switch sideways position (A right, B bottom, X top, Y left), not Xbox (A bottom, B right, X left, Y top) |
| top face button (printed X) | 2 | X | ❌ | Switch sideways position (A right, B bottom, X top, Y left), not Xbox (A bottom, B right, X left, Y top) |
| left face button (printed A) | 3 | Y | ❌ | Switch sideways position (A right, B bottom, X top, Y left), not Xbox (A bottom, B right, X left, Y top); printed A sends Y |
| grey Screenshot button | 8 | View/Back | ❌ | arrives as View/Back; may also take a phone screenshot |
| left rail button (SL) | 4 | LB | ✅ | SL/SR arrive as LB (intended); show SL/SR prompts |
| RB bumper, on the far edge (same input as SR) | 5 | RB | ✅ | SL/SR arrive as RB (intended); show SL/SR prompts |
| right rail button (SR) | 5 | RB | ✅ | SL/SR arrive as RB (intended); show SL/SR prompts |
| RT, on the far edge | 7 | RT | ✅ | LT only on the left half, RT only on the right |
| green Menu button | 9 | Menu/Start | ✅ | both halves send Menu/Start (9) |
| touchpad pressed in | 11 | R3 | ✅ | L3 on the left half, R3 on the right half; treat both as "stick press" |
| touchpad, up edge | 12 | D-pad Up | ✅ | correct direction, but as a digital D-pad, never an analog stick |
| touchpad, down edge | 13 | D-pad Down | ✅ | correct direction, but as a digital D-pad, never an analog stick |
| touchpad, left edge | 14 | D-pad Left | ✅ | correct direction, but as a digital D-pad, never an analog stick |
| touchpad, right edge | 15 | D-pad Right | ✅ | correct direction, but as a digital D-pad, never an analog stick |

## 5. Mixed prompt rules

The hardware has Xbox labels in a Switch-style split shape. The prompts should show both.

1. **Bind by role, not by half.** Use the shared-roles table. Both halves send the same index for the same role (face 0–3, directions 12–15, SL/SR 4/5, menu 9), so a single binding works on either half. The only per-half difference is stick press: 10 on the left half, 11 on the right.
2. **Prompt with the hardware label in the sideways grip.** Look glyphs up by `(half, index)`:
   - **Left half face role:** an arrow pointing the way that d-pad button faces sideways. A is ▶, B is ▼, X is ▲, Y is ◀.
   - **Right half face role:** the printed letter. A is printed **Y**, B is **B**, X is **X**, Y is printed **A**.
3. **SL / SR, never LB / RB, in split mode.** Indexes 4 and 5 always show SL and SR, even though they arrive as LB and RB and the bumper sends the same input.
4. **Use Switch concepts for the layout:** show a sideways left or right Joy-Con silhouette so each player knows which half they hold. Show Minus/Plus/Capture/Home as the role when a game expects Switch semantics.
5. **Tag prompts with the half when both are in use by one player.** For example, "L · ▶" or "R · Y". With one half per player, show only that half's prompts.
6. **No analog prompts in split mode.** Hide sensitivity sliders, "hold halfway" hints and second-stick prompts. Show a note if the game needs a right stick.
7. **Warnings:** don't map hold actions to the left Bluetooth button. Holding it 3 s starts pairing. Treat the right Screenshot button as possibly also taking a phone screenshot.

## 6. Still unverified

Measured on one unit over 4 labeling runs, on an Infinix GT 50 Pro (model X6891, Dimensity 8400 Ultimate, Android 16, build 16.3.0.155SP08; Chrome 157; its user agent reports "Android 10; K" because Chrome reduces the UA, so that is not the real OS version), Web Gamepad API with the `standard` mapping. Firmware version unknown.

- [x] D-pad left/right on `-L`: left=1, right=2, confirmed in 4 runs.
- [x] Touchpad click on `-R` sends index 11 (R3), confirmed in 3 runs.
- [x] SL/SR: **SL = index 4 and SR = index 5 on both halves**, same as a real Joy-Con. Confirmed by the sideways grip in the Infinix app (rail on top) and the photo of both rails.
- [x] Sideways grip: directions and face buttons match the Switch sideways Joy-Con layout by standard index. Derived from the measured map, matches the app's picture.
- [x] Touchpad: 4 edge zones confirmed in 3 runs; click = 11 on every hard press.
- [ ] Whether a native Android app sees the same indexes. Expect the same Android keycodes, because Chrome's standard mapping comes from Android's KEYCODE_BUTTON_* events. Not tested in a native app.
- [ ] Whether the right Screenshot button also takes a phone screenshot in split mode.
- [ ] Whether newer firmware changes any of this. Re-run the labeling tool after an update.
