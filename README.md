# TwoDo

A tiny open-source macOS menu bar app that holds **exactly one or two things
you actually need to do today** — nothing more. Add your items once, enable
"Launch at Login," and it pops up next to the menu bar the moment you log in.

Visual style is inspired by [Builder Battles](https://builderbattles.app) —
black background, bold uppercase type, a red "LIVE" indicator, thin red
accent lines.

## Download

Grab the latest build from
**[Releases](https://github.com/visrut7/mac-app-bar-reminder/releases/latest)**
— no Xcode or Swift toolchain required.

- **[TwoDo.dmg](https://github.com/visrut7/mac-app-bar-reminder/releases/latest/download/TwoDo.dmg)**
  — double-click, drag `TwoDo.app` onto `Applications`. Recommended.
- **[TwoDo.app.zip](https://github.com/visrut7/mac-app-bar-reminder/releases/latest/download/TwoDo.app.zip)**
  — unzip and move `TwoDo.app` to `/Applications` yourself.

### First launch

TwoDo isn't notarized by Apple (that requires a paid Developer ID), so on
first launch Gatekeeper will refuse to open it with an *"Apple could not
verify..."* warning. This is normal for indie/open-source Mac apps — do
**one** of the following:

- Right-click (or Control-click) `TwoDo.app` in Finder → **Open** → **Open**
  in the dialog that appears. Only needed once.
- Or: **System Settings → Privacy & Security**, scroll down, click **Open
  Anyway** next to the TwoDo message.

Once open, click the checklist icon in the menu bar and toggle **Launch at
Login** if you want it to auto-open every time you log in. If macOS hides
new menu bar icons (common when the bar is crowded), check **Control Center
→ Menu Bar Only** in System Settings and set TwoDo to always show.

## Features

- Menu bar icon — click to open, click elsewhere to dismiss
- Hard cap of **2** items (`0/2` → `2/2` counter in the header) — forces focus
- Check items off (strikethrough) or delete them
- Persists locally via `UserDefaults` — no accounts, no network, no tracking
- "Launch at Login" toggle (uses `ServiceManagement`/`SMAppService`) — when
  enabled, the app is itself the login item, so it opens straight into the
  popover on every login, no extra click needed
- No Dock icon, no app switcher entry (`LSUIElement`) — lives only in the
  menu bar

## Building from source

### Requirements

- macOS 13 (Ventura) or later
- Xcode 15+ / Swift 5.9+ command line tools (`xcode-select --install`)

### Build & run

```bash
./Scripts/build-app.sh
open build/TwoDo.app
```

This produces a real, double-clickable `build/TwoDo.app`. For "Launch at
Login" to behave the way macOS expects (and to survive reboots), copy it into
`/Applications`:

```bash
cp -R build/TwoDo.app /Applications/
open /Applications/TwoDo.app
```

To also build the `.dmg` installer locally:

```bash
./Scripts/build-app.sh
./Scripts/make-dmg.sh
open build/TwoDo.dmg
```

### Run without packaging (development)

```bash
swift run
```

Note: `SMAppService` (the login-item API) requires the binary to run from
inside a proper `.app` bundle, so use `./Scripts/build-app.sh` if you want to
test the "Launch at Login" toggle.

## Releasing a new version (maintainers)

```bash
git tag v1.1.0
git push origin v1.1.0
```

Pushing a tag matching `v*` is the only manual step — it triggers
[`.github/workflows/release.yml`](.github/workflows/release.yml), which
builds the app on a macOS GitHub Actions runner, packages both a `.dmg` and
`.app.zip`, and publishes them to a new GitHub Release automatically.
Every push to `main` also runs
[`.github/workflows/ci.yml`](.github/workflows/ci.yml), which builds the app
to catch breakage before you ever tag a release.

See **[RELEASING.md](RELEASING.md)** for the exact commands to watch a
release build and verify it actually published.

## Project structure

```
Package.swift                     Swift Package manifest (executable target)
Sources/TwoDo/
  main.swift                       Entry point — sets the app up as a menu bar agent
  AppDelegate.swift                Status item, popover, show/hide, event monitor
  TodoStore.swift                  Persistence + login-item registration
  TodoItem.swift                   Data model
  ContentView.swift                SwiftUI popover UI
  Theme.swift                      Colors shared across the UI
Resources/
  Info.plist                       App bundle metadata (LSUIElement, bundle id, ...)
  AppIcon.icns                     App icon (generated — see below)
Scripts/
  build-app.sh                     Builds release binary + assembles the .app bundle
  make-dmg.sh                      Packages build/TwoDo.app into build/TwoDo.dmg
  generate-icon.swift              Regenerates Resources/AppIcon.icns from code
.github/workflows/
  release.yml                      Tag push (v*) → build, package, publish GitHub Release
  ci.yml                           Every push/PR to main → build sanity check
```

To change the app icon, edit `Scripts/generate-icon.swift` and re-run:

```bash
swift Scripts/generate-icon.swift
```

## Why "TwoDo"

Most to-do apps let a backlog pile up until it's useless. This one physically
can't hold more than two items — so whatever's in there is, by definition,
what actually matters right now.

## License

MIT — see [LICENSE](LICENSE).
