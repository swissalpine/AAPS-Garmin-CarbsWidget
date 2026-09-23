# Patch OpenApsAIMI — endpoint Garmin `/mode`

Branche cible : **`dev_OAPSAIMI`**

Ces fichiers ont déjà été appliqués dans `/Users/mtr/StudioProjects/OpenApsAIMI` (même commit).

## Fichiers

```
plugins/sync/src/main/kotlin/app/aaps/plugins/sync/garmin/LoopHub.kt
plugins/sync/src/main/kotlin/app/aaps/plugins/sync/garmin/LoopHubImpl.kt
plugins/sync/src/main/kotlin/app/aaps/plugins/sync/garmin/GarminPlugin.kt
plugins/sync/src/test/kotlin/app/aaps/plugins/sync/garmin/GarminPluginTest.kt
```

## Vérification effectuée

- `:plugins:sync:compileFullDebugKotlin` → **BUILD SUCCESSFUL**
- `:plugins:aps:testFullDebugUnitTest --tests TherapyFclDetectionTest` → **BUILD SUCCESSFUL**
- Suite unit test `plugins:sync` globale : déjà cassée en amont (workers NS / LoopHubTest) — hors scope

## API

`POST /mode?mode=fcl&duration=30&key=YOUR_KEY`
