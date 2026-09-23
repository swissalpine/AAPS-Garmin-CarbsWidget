# AIMI Modes Widget (Garmin)

Widget Connect IQ pour activer les modes OpenApsAIMI depuis la montre :

| Menu | Keyword HTTP | Durée |
|------|--------------|-------|
| BFAST | `bfast` | 60 |
| LUNCH | `lunch` | 60 |
| DINNER | `dinner` | 60 |
| HIGH CARB | `highcarb` | 90 |
| FCL | `fcl` | 30 |
| STOP | `stop` | 1 |

Envoie : `POST http://127.0.0.1:28891/mode?mode=…&duration=…&key=…`

## Prérequis AAPS (OpenApsAIMI `dev_OAPSAIMI`)

1. Appliquer le patch Garmin `/mode` (fichiers sous `.openapsaimi/plugins/sync/.../garmin/` ou recopier depuis ce workspace).
2. Compiler / installer OpenApsAIMI.
3. Config Builder → **Garmin** activé.
4. Préférences Garmin :
   - Serveur HTTP local = **ON**
   - Port = **28891** (défaut)
   - Request Key = même valeur que dans `settings.mc`

## Build + déploiement sur la montre

### 1. Préparer les settings

```bash
cd aimi-modes-widget
cp source/settings.mc.example source/settings.mc
# Éditer source/settings.mc : garminKey = votre clé AAPS
```

### 2. Ouvrir dans Visual Studio Code

1. Installer l’extension **Monkey C** (Garmin Connect IQ).
2. Installer le **Connect IQ SDK** via Garmin SDK Manager.
3. File → Open Folder → `aimi-modes-widget`.
4. Vérifier que votre montre (ex. `venux1`) est dans `manifest.xml` (déjà incluse).

### 3. Compiler

- Command Palette → **Monkey C: Build for Device…**
- Choisir votre modèle (ex. Venu X1).
- Ou **Monkey C: Run** sur le simulateur pour un smoke test UI.

Le fichier `.prg` / package est généré dans `bin/`.

### 4. Sideload sur la montre

1. Montre allumée, Bluetooth OK, **Garmin Connect Mobile** ouvert sur le téléphone.
2. Brancher la montre en USB **ou** utiliser le sideload CIQ :
   - VS Code → **Monkey C: Build for Device** puis installer via Garmin Express / Connect IQ App Manager,
   - ou copier le `.prg` généré dans le dossier GARMIN/APPS de la montre (USB mass storage, selon modèle).
3. Sur la montre : ajouter le widget **AIMI Modes** à un écran de widgets.

### 5. Test rapide

1. Ouvrir le widget → SELECT → choisir **LUNCH**.
2. SELECT à nouveau → confirmation → envoi.
3. Dans AAPS : TherapyEvent NOTE `lunch 60` doit apparaître.
4. Pour FCL : note `fcl 30` (fenêtre de détection min. 60 min côté `therapy.kt`).

### Dépannage

| Symptôme | Cause probable |
|----------|----------------|
| Error 401 | Mauvaise `garminKey` |
| Error 404 | Endpoint `/mode` absent (AAPS pas patché) ou mauvaise URL |
| Error −400 / network | Garmin Connect pas actif / HTTP local OFF |
| Rien dans AAPS | Port différent de 28891 |

## Structure

```
aimi-modes-widget/
  source/AimiModesWidgetApp.mc
  source/AimiModesWidgetView.mc
  source/AimiModesWidgetGlance.mc
  source/settings.mc.example
  source/settings.mc          # local, gitignoré
  manifest.xml
  monkey.jungle
```
