# Pocket AI — a private LLM that runs on your iPhone

Pocket AI is a SwiftUI chat app that runs an open-source language model **entirely on the iPhone**
using Apple's [MLX](https://github.com/ml-explore/mlx-swift-lm) on the GPU. The first launch downloads
the model you pick from Hugging Face. After that it works offline and nothing leaves the device.

| Model | Download | Recommended device |
|---|---|---|
| Qwen3 0.6B (default) | ~350 MB | Any iPhone with an A14 chip or newer |
| Llama 3.2 1B | ~700 MB | iPhone 13 or newer |
| Gemma 3 1B | ~750 MB | iPhone 13 or newer |
| Qwen3 1.7B | ~1 GB | iPhone 15 Pro or newer |
| Llama 3.2 3B | ~1.8 GB | iPhone 15 Pro or newer (8 GB RAM) |

To add another model, put any `mlx-community/*-4bit` repo in `Sources/ModelOption.swift`.

## Get it onto TestFlight (no Mac needed)

The workflow `.github/workflows/testflight.yml` builds the app on a GitHub-hosted Mac and uploads it
to TestFlight. You only need an **Apple Developer Program** membership ($99/year).

### 1. Create the app in App Store Connect
1. Go to [developer.apple.com → Identifiers](https://developer.apple.com/account/resources/identifiers/list),
   add an **App ID** such as `com.yourname.pocketai`, and enable the **Increased Memory Limit** capability.
2. Go to [App Store Connect → Apps](https://appstoreconnect.apple.com/apps), choose **+ → New App**,
   pick iOS, and select that bundle ID.

### 2. Create an App Store Connect API key
App Store Connect → **Users and Access → Integrations → App Store Connect API** → generate a key with
the **Admin** role (automatic signing needs it to create certificates and profiles).
Note the **Key ID** and the **Issuer ID**, and download the `.p8` file. You can only download it once.

### 3. Add the secrets to GitHub
In this repo, open **Settings → Secrets and variables → Actions**.

| Kind | Name | Value |
|---|---|---|
| Secret | `ASC_KEY_ID` | Key ID from step 2 |
| Secret | `ASC_ISSUER_ID` | Issuer ID from step 2 |
| Secret | `ASC_KEY_P8` | Full text of the `.p8` file, including the `BEGIN`/`END` lines |
| Secret | `APPLE_TEAM_ID` | 10-character Team ID, shown under developer.apple.com → Membership |
| Variable | `BUNDLE_ID` | The bundle ID from step 1, e.g. `com.yourname.pocketai` |

### 4. Run the build
Once this code is on `main`, open **Actions → "Pocket AI → TestFlight" → Run workflow**.
The workflow also runs on every push to `main` that changes `PocketAI/`. A build takes about 15–25 minutes.
Apple then processes it for another 5–15 minutes, after which it shows up in App Store Connect → TestFlight.

### 5. Install it on your phone
In App Store Connect → TestFlight, add yourself under **Internal Testing**. Then install the
**TestFlight** app from the App Store and accept the invite.

## Building locally on a Mac (optional)
```bash
brew install xcodegen
cd PocketAI && xcodegen generate && open PocketAI.xcodeproj
```
Set your team under *Signing & Capabilities* and run on a real iPhone. MLX needs a Metal GPU, so the
Simulator works poorly.

## Project layout
- `project.yml`: XcodeGen spec (targets, Swift packages, entitlements, Info.plist)
- `Sources/LLMEngine.swift`: downloads and loads the model, streams tokens via `ChatSession`
- `Sources/ChatView.swift`: chat UI, model picker, and settings
- `Sources/ModelOption.swift`: list of models to choose from
- `ExportOptions.plist`: tells `xcodebuild` to upload the build straight to App Store Connect
