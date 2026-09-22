# Releasing TwoDo

A step-by-step record of how a release actually gets published — the real
commands, not just theory. Everything here is driven by
[`.github/workflows/release.yml`](.github/workflows/release.yml); nothing is
done manually through the GitHub website.

## 1. Commit and push your changes as normal

```bash
git add -A
git commit -m "..."
git push origin main
```

Every push to `main` also runs
[`.github/workflows/ci.yml`](.github/workflows/ci.yml), which just builds
the app to catch breakage early. It does **not** publish anything.

## 2. Tag it — this is the actual trigger

GitHub Releases aren't a "file you add" or a button you click by default —
they're created by the `release.yml` workflow the moment a tag matching
`v*` is pushed. Use [semantic versioning](https://semver.org/)
(`vMAJOR.MINOR.PATCH`):

```bash
git tag v1.0.0
git push origin v1.0.0
```

That's genuinely the only manual step. Pushing the tag is what starts
everything below.

## 3. Watch it build (recommended — don't just assume it worked)

```bash
gh run list --limit 5                       # find the "Release" run for your tag
gh run watch <run-id> --exit-status          # stream it live, exits non-zero on failure
```

Inside that workflow run, in order:

```bash
VERSION="1.0.0" ./Scripts/build-app.sh       # builds + stamps the version into Info.plist
./Scripts/make-dmg.sh                        # packages build/TwoDo.dmg
ditto -c -k --sequesterRsrc --keepParent build/TwoDo.app build/TwoDo.app.zip
gh release create v1.0.0 \
  build/TwoDo.dmg build/TwoDo.app.zip \
  --title "TwoDo v1.0.0" --generate-notes
```

`gh release create` both creates the release *and* publishes it
(non-draft) in one step, with the two files attached and release notes
auto-generated from the commits since the last tag.

## 4. Verify it's actually live — GitHub's UI can lag/cache

```bash
gh release view v1.0.0
```

Check the real, ground-truth state via the API rather than trusting a
browser tab you had open before the workflow finished (it can show a
stale "Draft" badge until you refresh):

```bash
gh api repos/<owner>/<repo>/releases --jq '.[] | {tag: .tag_name, draft: .draft}'
```

Confirm the public download link actually resolves (a `302` redirect to a
real asset, not a `404`):

```bash
curl -sIL https://github.com/<owner>/<repo>/releases/latest/download/TwoDo.dmg
```

## Shipping the next version

Same as step 2, with the next tag:

```bash
git tag v1.1.0
git push origin v1.1.0
```

## Building locally without tagging (for testing before you release)

```bash
./Scripts/build-app.sh          # → build/TwoDo.app
./Scripts/make-dmg.sh           # → build/TwoDo.dmg
open build/TwoDo.dmg
```

Useful for sanity-checking a build before committing to a public tag —
tags/releases are meant to be permanent, so it's worth testing locally
first.
