# Patch OpenApsAIMI — endpoint Garmin `/mode`

Branche cible : **`dev_OAPSAIMI`**

## Fichiers

```
plugins/sync/src/main/kotlin/app/aaps/plugins/sync/garmin/LoopHub.kt
plugins/sync/src/main/kotlin/app/aaps/plugins/sync/garmin/LoopHubImpl.kt
plugins/sync/src/main/kotlin/app/aaps/plugins/sync/garmin/GarminPlugin.kt
plugins/sync/src/test/kotlin/app/aaps/plugins/sync/garmin/GarminPluginTest.kt
```

Copy from `aaps-patches/garmin-mode/` in this repo.

## HTTP `/sgv.json` extras (Blueprint / Cockpit / Atelier)

On the first glucose point, when available:

| field | type | meaning |
|-------|------|---------|
| `target` | int | current target mg/dL (active TT midpoint, else profile) |
| `mode` | string | AIMI therapy label: `FCL`, `DINNER`, `LUNCH`, `BFAST`, `SPORT`, … |
| `tbrMins` | int | remaining temporary basal minutes |

Also still emits `tir` (Pilot ring), `tbr` (`U/h/%`), `iob`, `cob`.

## API

`POST /mode?mode=lunch&duration=60&key=YOUR_KEY`

- **NOTE text** = keyword only (`lunch`, `fcl`, `sport`, …) — never `"lunch 60"`.
- **TherapyEvent.duration** = `duration` query (minutes).
- Modes: `bfast`, `lunch`, `dinner`, `highcarb`, `coffee` (90), `fcl`, `sport`, `stop` (+ `meal`/`snack` / `cafe` if needed).
- **FCL** also calls `postTempTarget(80, 30)` (mg/dL × minutes).

## Why keyword-only notes

`Therapy` (`therapy.kt`) arms modes with `note.contains("lunch")` and ends them with
`now <= event.timestamp + event.duration`. Embedding minutes in the note string is redundant and can
interfere with detection.
