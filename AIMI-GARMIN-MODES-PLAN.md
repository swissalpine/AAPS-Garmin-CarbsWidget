# Plan de modifications — Widget Garmin modes AIMI

Document de référence pour connecter une montre Garmin à **OpenApsAIMI** ([MTR93600/OpenApsAIMI](https://github.com/MTR93600/OpenApsAIMI.git)) et activer les modes repas **bfast**, **lunch**, **dinner**, **highcarb** depuis le poignet.

Basé sur l’analyse du dépôt **AAPS-Garmin-CarbsWidget** (swissalpine) et du clone local `.openapsaimi/` (branche `master` au moment de l’analyse).

---

## Sommaire

1. [Architecture rappel](#1-architecture-rappel)
2. [Corrections sur l’existant](#2-corrections-sur-lexistant)
3. [Modifications OpenApsAIMI (Android)](#3-modifications-openapsaimi-android)
4. [Nouveau widget Garmin (Connect IQ)](#4-nouveau-widget-garmin-connect-iq)
5. [Configuration utilisateur](#5-configuration-utilisateur)
6. [Tests et validation](#6-tests-et-validation)
7. [Risques et limites](#7-risques-et-limites)
8. [Checklist récapitulative](#8-checklist-récapitulative)

---

## 1. Architecture rappel

```
Montre (Monkey C widget)
    │  Comm.makeWebRequest → HTTP
    ▼
Téléphone (Garmin Connect fait le pont)
    │  localhost 127.0.0.1
    ▼
OpenApsAIMI — GarminPlugin.HttpServer
    │  LoopHubImpl
    ▼
TherapyEvent (NOTE)  ex. note = "lunch 60", duration = 60 min
    │
    ▼
therapy.kt → lunchTime / bfastTime / dinnerTime / highCarbTime
    │
    ▼
DetermineBasalAIMI2 → prébolus P1/P2, SMB, etc.
```

**OpenApsAIMI** embarque déjà le plugin Garmin sous :

`plugins/sync/src/main/kotlin/app/aaps/plugins/sync/garmin/`

Il n’est **pas** nécessaire de copier les dossiers depuis le fork swissalpine si vous compilez OpenApsAIMI directement.

| Paramètre | Valeur par défaut (OpenApsAIMI) |
|-----------|----------------------------------|
| Port HTTP local | **28891** (`GarminIntKey.LocalHttpPort`) |
| Interface d’écoute | **127.0.0.1** (IPv4 uniquement) |
| Authentification | Query `key=` = préférence `GarminStringKey.RequestKey` |

Endpoints HTTP **déjà présents** :

| Chemin | Rôle |
|--------|------|
| `/get` | Glycémies + envoi HR/steps montre → AAPS |
| `/carbs?carbs=N&key=…` | Saisie glucides |
| `/bolus?bolus=U&key=…` | Bolus |
| `/temptarget?target=&duration=&key=…` | Cible temporaire |
| `/connect` | Connexion / déconnexion pompe |
| `/sgv.json` | Format Nightscout (watchfaces) |

**Manquant pour les modes AIMI :** `/mode` (à ajouter).

---

## 2. Corrections sur l’existant

### 2.1 Widget Carbs — appel HTTP incompatible avec le plugin Garmin

**Fichier :** `source/CarbsWidgetView.mc` — fonction `frageURL()`

**Problème :** le widget envoie un **POST JSON** type Nightscout :

```monkey-c
Comm.makeWebRequest(url, {
    "eventType" => "Snack Bolus",
    "carbs" => carbs,
    "enteredBy" => "Garmin Widget"
}, {
    :method => Comm.HTTP_REQUEST_METHOD_POST,
    :headers => { "Content-Type" => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON },
    ...
});
```

Le plugin Garmin (`GarminPlugin.onPostCarbs`) lit uniquement les **paramètres d’URL** :

```kotlin
fun onPostCarbs(uri: URI): CharSequence {
    postCarbs(getQueryParameter(uri, "carbs", 0L).toInt())
    return ""
}
```

Le corps JSON est **ignoré** (`requestHandler` ne transmet pas le body à l’action). Résultat probable : `carbs=0` → aucun glucide enregistré.

**Correction recommandée :**

1. **`source/settings.mc`** (fichier local, gitignoré) — définir par exemple :

```monkey-c
var url = "http://127.0.0.1:28891/carbs";
var garminKey = "VOTRE_CLE_AAPS";  // identique à AAPS → Plugin Garmin → Request Key
```

2. **`frageURL()`** — retirer le JSON Nightscout ; passer les paramètres en query string (sans header `Content-Type: application/json`) :

```monkey-c
function frageURL() {
    circle = Gfx.COLOR_WHITE;
    Comm.makeWebRequest(
        url,
        { "carbs" => carbs, "key" => garminKey },
        { :method => Comm.HTTP_REQUEST_METHOD_POST,
          :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON },
        method(:verarbeiteWerte)
    );
    abfrage = 3;
    return true;
}
```

3. Vérifier le **port** : OpenApsAIMI utilise **28891** par défaut ; l’ancienne doc swissalpine mentionnait parfois **28890** — aligner montre et AAPS.

4. **Optionnel :** renommer `eventType` / `enteredBy` si un jour le plugin accepte le JSON ; aujourd’hui ils sont inutiles.

---

### 2.2 Fichier `settings.mc` absent du dépôt

**Fichier :** `.gitignore` contient `source/settings.mc`

**Problème :** `url` est référencé dans `CarbsWidgetView.mc` mais jamais défini dans les sources versionnées → **échec de compilation** sans fichier local.

**Correction recommandée :**

- Ajouter un modèle versionné : `source/settings.mc.example`

```monkey-c
// Copier vers source/settings.mc et adapter
var url = "http://127.0.0.1:28891/carbs";
var garminKey = "CHANGEZ_MOI";
```

- Documenter dans le README la création de `settings.mc` avant build.

---

### 2.3 README — dépendance swissalpine vs OpenApsAIMI

**Fichier :** `README.md`

**Problème :** le README pointe vers le fork **swissalpine/AndroidAPS** et des branches (`sport-changes-3.3.2.0`, `3.3.3-mod-alpha`) pour copier le plugin Garmin. Avec **OpenApsAIMI**, le plugin est **déjà intégré**.

**Correction recommandée :**

- Ajouter une section « OpenApsAIMI » : activer le plugin dans Config Builder, serveur HTTP local, clé partagée.
- Conserver la section swissalpine pour les utilisateurs AAPS stock / fork sport.

---

## 3. Modifications OpenApsAIMI (Android)

Cible : [MTR93600/OpenApsAIMI](https://github.com/MTR93600/OpenApsAIMI.git)

### 3.1 `LoopHub.kt` — nouvelle méthode

**Fichier :** `plugins/sync/src/main/kotlin/app/aaps/plugins/sync/garmin/LoopHub.kt`

**Ajout :**

```kotlin
/** Active un mode AIMI via TherapyEvent NOTE (ex. "lunch 60"). */
fun postTherapyMode(keyword: String, durationMin: Int)
```

Placer à côté de `postCarbs` / `postBolus` / `postTempTarget`.

---

### 3.2 `LoopHubImpl.kt` — implémentation

**Fichier :** `plugins/sync/src/main/kotlin/app/aaps/plugins/sync/garmin/LoopHubImpl.kt`

**Comportement attendu** (aligné sur `RemoteControlFragment.sendTherapyEventMode` + `therapy.kt`) :

| Entrée | Action |
|--------|--------|
| `keyword = "stop"`, `durationMin` ignoré | Insérer NOTE `stop` (durée courte ou 0 selon logique existante) ; déclencher reset modes via `therapy.kt` |
| Autre keyword | Insérer `TE` type `NOTE`, `note = "$keyword $durationMin"`, `duration = durationMin` en ms |
| Source | `Sources.Garmin` |
| Log utilisateur | `Action.THERAPYEVENT` ou équivalent existant pour NOTE |

**Pseudo-code :**

```kotlin
override fun postTherapyMode(keyword: String, durationMin: Int) {
    val now = dateUtil.now()
    val durationMs = TimeUnit.MINUTES.toMillis(durationMin.toLong().coerceAtLeast(0))
    val note = if (keyword.equals("stop", ignoreCase = true)) "stop"
               else "$keyword $durationMin"
    val te = TE(
        timestamp = now,
        type = TE.Type.NOTE,
        glucoseUnit = GlucoseUnit.MGDL,
        note = note,
        duration = durationMs
    )
    disposable += persistenceLayer.insertOrUpdateTherapyEvent(te)
        .subscribeOn(...)
        .subscribe(...)
}
```

**Mots-clés valides** (déjà reconnus par `therapy.kt` sur `dev_OAPSAIMI`) :

| Mode widget | `keyword` HTTP | Détection `therapy.kt` |
|-------------|----------------|-------------------------|
| Petit-déjeuner | `bfast` | `bfast` ou `breakfast` |
| Déjeuner | `lunch` | `lunch` |
| Dîner | `dinner` | `dinner` |
| High carb | `highcarb` | `highcarb` ou `high carb` |
| FCL | `fcl` | `fcl` (min window 60 min, pas de prébolus) |
| Annuler | `stop` | `stop` |

**Durées par défaut suggérées** :

| Mode | Minutes |
|------|---------|
| bfast | 60 |
| lunch | 60 |
| dinner | 60 |
| highcarb | 90 |
| fcl | 30 |
| stop | 1 |

**Note :** le contrôle distant envoie aussi une note `AIMI:PIN mode lunch 60` pour l’audit. Depuis Garmin, la note **`lunch 60` seule suffit** pour `therapy.kt`. Ajouter le format AIMI+PIN n’est utile que si vous voulez la même trace NS / PIN parent.

---

### 3.3 `GarminPlugin.kt` — endpoint `/mode`

**Fichier :** `plugins/sync/src/main/kotlin/app/aaps/plugins/sync/garmin/GarminPlugin.kt`

**Dans `setupHttpServer()`**, ajouter :

```kotlin
registerEndpoint("/mode", requestHandler(::onPostMode))
```

**Nouvelle fonction :**

```kotlin
@VisibleForTesting
fun onPostMode(uri: URI): CharSequence {
    val mode = getQueryParameter(uri, "mode") ?: ""
    val duration = getQueryParameter(uri, "duration", 0)
    if (mode.isBlank()) {
        return "" // ou message d'erreur JSON
    }
    loopHub.postTherapyMode(mode.lowercase(), duration)
    return ""
}
```

**Paramètres HTTP :**

| Paramètre | Obligatoire | Exemple |
|-----------|-------------|---------|
| `key` | Oui (si clé configurée dans AAPS) | `key=abc123` |
| `mode` | Oui | `lunch`, `bfast`, `dinner`, `highcarb`, `stop` |
| `duration` | Non (défaut selon mode côté serveur ou client) | `60` |

**Validation côté serveur (recommandé) :**

- Liste blanche : `bfast`, `lunch`, `dinner`, `highcarb`, `stop` (+ éventuellement `meal`, `snack` plus tard).
- `duration` plafonné (ex. 1–480 min).
- Si `duration` absent : appliquer la durée par défaut du `ModePreset` correspondant.

---

### 3.4 Tests unitaires

**Fichiers à étendre :**

| Fichier | Ajouts |
|---------|--------|
| `plugins/sync/src/test/kotlin/.../garmin/GarminPluginTest.kt` | `onPostMode` avec URI `?mode=lunch&duration=60&key=…` ; vérifier appel `loopHub.postTherapyMode` |
| `LoopHubImpl` (si tests dédiés existent) | insertion `TE` avec bonne note et durée |
| `HttpServerTest.kt` | POST `/mode?...` retourne 200 |

**Cas de test minimum :**

- Mode valide + clé valide → 200, `postTherapyMode` appelé.
- Clé invalide → 401 (comportement existant `requestHandler`).
- `mode` inconnu → 400 ou ignoré (à décider).
- `stop` → note `stop`.

---

### 3.5 Documentation OpenApsAIMI (optionnel)

**Fichiers suggérés :** `README.md` ou `_docs/garmin-widget.md`

Contenu :

- Activer **Plugin Garmin** + **Serveur HTTP local**.
- Port et clé partagée avec la montre.
- Liste des endpoints dont `/mode`.
- Lien vers le repo widget Garmin.

---

## 4. Nouveau widget Garmin (Connect IQ)

Recommandation : **nouveau projet** (ex. `AAPS-Garmin-AimiModesWidget`) plutôt que surcharger le widget Carbs — UX et manifest distincts.

### 4.1 Structure projet (miroir Carbs)

```
AAPS-Garmin-AimiModesWidget/
├── manifest.xml
├── monkey.jungle
├── source/
│   ├── AimiModesWidgetApp.mc
│   ├── AimiModesWidgetView.mc      # UI + menu + HTTP
│   ├── AimiModesWidgetGlance.mc
│   └── settings.mc                 # gitignoré
│   └── settings.mc.example         # versionné
├── resources/
│   ├── strings/strings.xml
│   ├── layouts/layout.xml
│   └── drawables/drawables.xml
└── README.md
```

### 4.2 `settings.mc.example`

```monkey-c
var url = "http://127.0.0.1:28891/mode";
var garminKey = "VOTRE_CLE_AAPS";

// Durées par défaut (minutes) — peuvent être surchargées par le menu
var durationBfast = 60;
var durationLunch = 60;
var durationDinner = 60;
var durationHighcarb = 90;
```

### 4.3 Logique UI (`AimiModesWidgetView.mc`)

Reprennir le pattern de `CarbsWidgetView.mc` :

| État `abfrage` | Comportement |
|----------------|--------------|
| 1 | Écran d’accueil — « SELECT pour choisir un mode » |
| 2 | Menu : BFAST / LUNCH / DINNER / HIGH CARB / (optionnel) STOP |
| 3 | Attente réponse HTTP |
| 4 | Succès (vert) ou erreur (rouge) |

**Menu suggéré :**

```monkey-c
menu.setTitle("AIMI Mode");
menu.addItem("BFAST", :bfast);
menu.addItem("LUNCH", :lunch);
menu.addItem("DINNER", :dinner);
menu.addItem("HIGH CARB", :highcarb);
menu.addItem("STOP", :stop);   // optionnel mais utile
```

**Envoi HTTP (corrigé dès le départ) :**

```monkey-c
function sendMode(modeKeyword, durationMin) {
    Comm.makeWebRequest(
        url,
        { "mode" => modeKeyword, "duration" => durationMin, "key" => garminKey },
        { :method => Comm.HTTP_REQUEST_METHOD_POST,
          :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON },
        method(:onResponse)
    );
}
```

Mapping sélection menu → paramètres :

| Item | `mode` | `duration` |
|------|--------|------------|
| BFAST | `bfast` | `durationBfast` |
| LUNCH | `lunch` | `durationLunch` |
| DINNER | `dinner` | `durationDinner` |
| HIGH CARB | `highcarb` | `durationHighcarb` |
| STOP | `stop` | `0` |

**Amélioration UX (optionnelle, phase 2) :**

- Sous-menu durée : 30 / 60 / 90 / 120 min avant envoi.
- Afficher le mode sélectionné sur l’écran de confirmation (« Push LUNCH 60 min to AAPS? »).

### 4.4 `manifest.xml`

- `type="widget"`.
- Permission `Communications`.
- Reprendre la liste `iq:product` du widget Carbs (ou réduire aux montres cibles).
- Nouvel `iq:application id` (UUID unique).

### 4.5 `AimiModesWidgetGlance.mc`

Texte court : `AIMI` / `modes` (comme `CARBS` / `to AAPS` sur le widget existant).

### 4.6 README widget

- Prérequis : OpenApsAIMI avec plugin Garmin + HTTP local.
- Création `settings.mc` depuis l’example.
- Build VS Code (extension Monkey C) + sideload Garmin Express.
- Alignement port / clé avec AAPS.
- Avertissement sécurité (contrôle insulinique à distance).

---

## 5. Configuration utilisateur

### 5.1 Sur le téléphone (OpenApsAIMI)

1. **Config Builder** → activer **Plugin Garmin**.
2. Préférences Garmin :
   - **Serveur HTTP local** : ON.
   - **Port** : `28891` (ou celui choisi).
   - **Request Key** : chaîne secrète (ex. 8–32 caractères).
3. Recompiler / installer l’APK modifié si vous avez ajouté `/mode`.

### 5.2 Sur la montre

1. Copier `settings.mc.example` → `settings.mc`.
2. Renseigner `garminKey` identique à AAPS.
3. Vérifier `url` : `http://127.0.0.1:PORT/mode`.
4. Build + installer le widget sur la montre compatible.
5. Ajouter le widget à un écran de la montre ; garder Garmin Connect actif sur le téléphone.

### 5.3 Réseau localhost Garmin

Le plugin écoute **127.0.0.1** IPv4. Garmin Connect sur Android route les requêtes de la montre vers le téléphone ; cela fonctionne lorsque l’écosystème swissalpine / buessow est validé sur votre couple montre+téléphone. Tester sur **matériel réel** (le simulateur ne reproduit pas toujours le pont HTTP).

---

## 6. Tests et validation

### 6.1 Tests AAPS (sans montre)

Avec serveur HTTP actif et clé configurée :

```bash
# Exemple depuis adb shell sur le téléphone (ou curl via port forwarding)
curl -X POST "http://127.0.0.1:28891/mode?mode=lunch&duration=60&key=VOTRE_CLE"
```

**Attendu :**

- Réponse HTTP **200**.
- Nouveau TherapyEvent NOTE, note contenant `lunch` et `60`.
- Logs `LTag.GARMIN` : réception `/mode`.
- Après cycle algo : `therapy.lunchTime == true` pendant la durée.

Répéter pour `bfast`, `dinner`, `highcarb`, `stop`.

### 6.2 Tests widget Carbs (après correction §2.1)

```bash
curl -X POST "http://127.0.0.1:28891/carbs?carbs=10&key=VOTRE_CLE"
```

**Attendu :** glucides +10 g dans AAPS (Actions / traitement).

### 6.3 Tests montre

| Étape | Vérification |
|-------|----------------|
| Ouvrir widget modes | Menu 4 modes visible |
| Choisir LUNCH | Écran « Contacting AAPS… » |
| Succès | Cercle vert, « added to AAPS » |
| AAPS | NOTE `lunch 60` actif, dashboard mode déjeuner |
| High carb 90 min | `highCarbTime` actif, prébolus renforcé selon prefs AIMI |
| STOP | Modes repas désactivés (`stopTime` / reset) |

### 6.4 Tests de non-régression

- Watchface glucose (CIQ / `/sgv.json`) inchangé.
- `/bolus` et `/temptarget` toujours fonctionnels si widgets swissalpine utilisés.
- Sync Nightscout des TherapyEvents (si NS actif).

---

## 7. Risques et limites

| Risque | Mitigation |
|--------|------------|
| Activation mode sans PIN (vs Remote Control) | Acceptable usage personnel ; ne pas exposer la clé Garmin |
| Mauvais port / clé | Message d’erreur HTTP 401/404 sur montre ; doc settings.mc |
| JSON vs query (Carbs) | Correction §2.1 obligatoire |
| `high carb` vs `highcarb` | Utiliser **`highcarb`** (sans espace) côté HTTP |
| Durée trop courte | Prébolus P1/P2 peuvent ne pas se déclencher — respecter 60/90 min |
| Responsabilité médicale | Usage « at your own risk », comme le README swissalpine |
| Branche OpenApsAIMI | Rebase régulier ; conflits possibles sur `GarminPlugin.kt` |

---

## 8. Checklist récapitulative

### OpenApsAIMI

- [ ] `LoopHub.postTherapyMode(keyword, durationMin)`
- [ ] `LoopHubImpl.postTherapyMode` → `TE` NOTE + durée
- [ ] `GarminPlugin.registerEndpoint("/mode", …)`
- [ ] `GarminPlugin.onPostMode` + validation mots-clés
- [ ] Tests unitaires `GarminPluginTest` / `HttpServerTest`
- [ ] Doc utilisateur plugin Garmin + `/mode`

### Widget Carbs (corrections)

- [ ] `settings.mc.example` + doc README
- [ ] `frageURL()` : query `carbs` + `key`, sans JSON Nightscout
- [ ] Port 28891 aligné avec OpenApsAIMI
- [ ] README : section OpenApsAIMI

### Nouveau widget AIMI Modes

- [ ] Projet Connect IQ (App / View / Glance)
- [ ] Menu bfast / lunch / dinner / highcarb / stop
- [ ] HTTP POST `/mode` avec query params
- [ ] `settings.mc.example`
- [ ] manifest + permissions Communications
- [ ] README build & sideload

### Validation

- [ ] curl `/mode` depuis téléphone
- [ ] curl `/carbs` après correction
- [ ] Test montre réelle → TherapyEvent + algo AIMI
- [ ] Test STOP annule modes actifs

---

## Annexe A — Fichiers OpenApsAIMI de référence (déjà présents)

| Fichier | Rôle |
|---------|------|
| `plugins/sync/.../garmin/GarminPlugin.kt` | Serveur HTTP, endpoints |
| `plugins/sync/.../garmin/LoopHubImpl.kt` | Carbs, bolus, TT |
| `plugins/sync/.../garmin/HttpServer.kt` | Parser HTTP localhost |
| `plugins/aps/.../openAPSAIMI/therapy.kt` | Détection modes actifs |
| `plugins/sync/.../nsShared/ModePreset.kt` | Mots-clés et durées par défaut |
| `plugins/sync/.../nsShared/RemoteControlFragment.kt` | Référence envoi `lunch 60` |

## Annexe B — Fichiers widget Carbs (ce dépôt)

| Fichier | Rôle |
|---------|------|
| `source/CarbsWidgetView.mc` | UI + HTTP (à corriger §2.1) |
| `source/CarbsWidgetApp.mc` | Point d’entrée |
| `source/CarbsWidgetGlance.mc` | Vue glance |
| `.gitignore` | Exclut `settings.mc` |

---

*Document généré pour le projet AAPS-Garmin-CarbsWidget — analyse OpenApsAIMI `master` et sources widget swissalpine.*
