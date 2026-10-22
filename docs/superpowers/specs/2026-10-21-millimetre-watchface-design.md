# Millimétré — design (2026-10-21)

Paper millimetric lab-log ancestor of Blueprint. Cream grid sheet; measured glucose in navy ink; +60m prediction in grey pencil dashes; green highlighter TGT band; red SMB margin ticks; grey basal staircase; red rubber-stamp mode (rotated). Only light “day” skin in the series.

## Scope (full chain)

1. **Watchface** on `dev/venu-x1-v2-millimetre` (`layoutStyle=9`, distinct UUID).
2. **AAPS HTTP** `/sgv.json` fields on the newest point: `basalHistory`, `smbHistory` (3h window), so staircase + ticks are real, not decorative.
3. **Packaging** like Blueprint: `manifest-millimetre.xml` + `monkey-millimetre.jungle` + `resources-millimetre/`.

## Visual (zero PNG assets)

| Element | Implementation |
|---|---|
| Sheet | Cream fill + blue 1px grid + red every 10 cells |
| Ink curve | Thick navy polyline + dots at samples |
| Pencil +60m | Grey dashed polyline (mockFuture until APS future lands) |
| TGT | Pale green fill ±10 mg/dL, dashed green edges, “TGT” label |
| SMB | Short red ticks under curve at `smbHistory` times |
| Basal | Grey step band in bottom ~18% of plot from `basalHistory` |
| Mode stamp | Runtime buffered bitmap, double frame, red ink, AffineTransform ~−8° |
| Alert | Red SGV + “HYPO”/“HYPER” stamp + red sheet frame + red-pencil predict hint |
| Chrome | Header (date \| time \| steps·HR); footer monospace `IOB \| TBR \| Δ \| TIR` |

## AAPS payload

On first `/sgv.json` object (same place as `target` / `mode` / `tbrMins`):

```json
"basalHistory": [{"t": 1699999800000, "p": 100}, {"t": 1700001600000, "p": 130}],
"smbHistory": [1699999900000, 1700000500000]
```

- **basalHistory**: staircase steps over last 3h — `t` = step start (ms), `p` = basal percent (100 = profile). Gaps → implicit 100 until next step. Built from `getTemporaryBasalsActiveBetweenTimeAndTime` + `convertedToPercent`; trailing open step to `now`.
- **smbHistory**: SMB bolus timestamps in last 3h (`BS.Type.SMB` via `getBolusesFromTime`).
- Watch keeps both on `data[0]` in `CGMWatchfaceBG.verarbeiteWerte`.

## Watch wiring

- `layoutStyle == 9` → `CGMWatchfaceMillimetre.draw` (+ helpers in `MillimetreDrawing.mc`).
- Graph time base: same 3h / accumulated readings as Blueprint.
- Basal/SMB X from `minutesFromNow` mapped into past 75% of plot width (prediction uses remaining 25%).
- If histories missing/empty: omit staircase and ticks (layout still valid).

## Non-goals

- Jauge / Horizon (separate concepts).
- APS true future curve (keep soft mockFuture).
- Dark-mode variant.

## Battery note

Light AMOLED fill costs more than Blueprint — accepted as a day skin.

## Validation

- Sideload PRG (Venu X1 + Venu 3S): cream grid, ink/pencil, stamp tilt, footer.
- With patched AAPS: TBR change → staircase steps; SMB → red ticks.
- Without histories: face still draws; no crash on null arrays.
