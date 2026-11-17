# controller-detect

A one-page tool that logs what the browser Gamepad API reports for each connected controller: index, id string, vendor and product IDs, mapping, buttons, axes and rumble support. It was built to check whether the Infinix GT NX controller shows up as one gamepad or two in split mode.

Live: https://controller.kuletxcore.workers.dev

## Use

1. Open the page in Chrome on the device the controller is connected to.
2. Press a button on the controller. Browsers hide gamepads until one is pressed.
3. Run **Split-mode test**: press something on the left half, then on the right half. It tells you if the halves are the same device, separate devices with the same id, or separate devices with different ids.
4. Use **Copy** or **Download .txt** to save the log.

## Deploy

```bash
npx wrangler deploy
```

## GT NX split-mode profile

- [`HANDOFF-gtnx-split-mode.md`](HANDOFF-gtnx-split-mode.md): what each half of the Infinix GT NX sends in split mode, and rules for mixed Xbox/Switch button prompts.
- [`gtnx-split-profile.json`](gtnx-split-profile.json): the same map as data. The site serves it at `/gtnx-split-profile.json`, and the Joy-Con view reads it.

## What the GT NX Controller is

The Infinix GT NX Controller is a Bluetooth phone controller that launched in September 2026, alongside the GT 50 Pro phone and the GT NX Station dock. It comes in two halves that clip onto either side of the phone, Switch-style.

Infinix's official product pages (Philippines):

- [GT NX Controller](https://wap.ph.infinixmobility.com/specs/xpower-10-pro). The URL says "xpower-10-pro", but the page is the controller's.
- [GT NX Controller Blood Strike](https://wap.ph.infinixmobility.com/GT-NX-Controller-Blood-Strike), a separate edition. The unit tested here doesn't carry the Blood Strike branding, but it still has native support for *Blood Strike*, NetEase's free-to-play battle royale shooter.

**Hardware.** These details come from press coverage, not an official spec sheet:

- Left half: a Hall-effect stick and a D-pad.
- Right half: XYBA buttons and an FPS touchpad, said to be 33 × 33 mm with 2000 × 2000 resolution. The touchpad works by swipe or in a mouse mode.
- Shoulder buttons and triggers on both halves, a 6-axis gyro, and vibration with three strengths set in XArena.
- Each half has its own 730 mAh battery, for a claimed ~22 hours of play.
- One retailer lists the weight as 219 g.
- Android and iOS are supported. Infinix phones show a connect pop-up; other phones need manual Bluetooth pairing.

**Modes** (switched in Infinix's XArena app):

- **Native mode:** full support in partner games, including Blood Strike, Asphalt Legends and Asphalt 8.
- **Combined mode:** one controller.
- **Split mode:** each half becomes its own controller, held sideways like a Joy-Con, for two-player games. This is the mode this repo maps.

**Price at launch:**

- Philippines: PHP 2,399 for the standard edition, PHP 2,499 for the Blood Strike Edition.
- Malaysia: RRP RM399, with a promo price of RM299.

Sources: [GizGuide review](https://www.gizguide.com/2026/10/infinix-gt-nx-controller-station-review.html), [TechNave review](https://technave.com/gadget/Infinix-GT-NX-Controller-and-GT-NX-Station-Review-A-New-Way-to-Play-Mobile-Games-47664.html), [FoneArena](https://www.fonearena.com/blog/493394/infinix-gt-nx-controller-gt-nx-station-features.html/amp), [Lowyat](https://www.lowyat.net/2026/405406/infinix-gt-nx-series-malaysia/), [ProPakistani](https://propakistani.pk/2026/09/26/infinix-launches-gaming-controller-with-mouse-like-accuracy-for-fps-gaming/), [Saiganak (weight)](https://saiganak.com/product/infinix-gt-nx-controller-gt-50-pro-gt-nt-station/).
