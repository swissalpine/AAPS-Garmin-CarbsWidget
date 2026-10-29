# Téléscripteur — design (2026-10-29)

Green-phosphor AIMI teleprinter. Dark AMOLED log skin: scrolling timestamped journal + fixed live strip. Complements Millimétré (paper) and Blueprint (oscilloscope).

## Scope

1. Watchface on `dev/venu-x1-v2-telescripteur` (`layoutStyle=10`, distinct UUID).
2. Packaging: `manifest-telescripteur.xml` + `monkey-telescripteur.jungle` + `resources-telescripteur/`.
3. Reuse existing AAPS fields: SGV history, `target`, `mode`, `tbr`, `tir`, `iob`, `smbHistory` (no new phone payload).

## Visual

| Zone | Content |
|---|---|
| Header | `AIMI·LOG` \| date time \| `CH1` |
| Scroll log | Newest at bottom; rows: `HH:MM  SGV nnn  d±n  IOB x.x` ; amber `* SMB u.uu U` ; amber `* MODE FCL` ; dim snapshot `TGT · TBR · TIR` |
| Live strip | Big SGV + trend/age ; 4 cells TGT \| TBR \| IOB \| TIR |
| Alert | Hypo/hyper: SGV + strip in red/amber phosphor |

No AffineTransform (Millimétré IQ! lesson). Primitives + system fonts only.

## Data → log

- SGV rows from `bgReadingsAccumulated` / `punkte` (last ~12–14 lines that fit).
- SMB rows from `smbHistory` timestamps interleaved by time.
- Mode: single `* MODE …` when `mode` non-empty (no mode history on phone).
- Snapshot line after newest SGV when target/tbr/tir present.

## Non-goals

- True scrolling animation / pager.
- Mode or TBR history beyond current values.
- Jauge / Horizon.
