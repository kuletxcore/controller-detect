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
