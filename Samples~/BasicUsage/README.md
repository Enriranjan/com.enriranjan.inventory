# Basic Usage Sample

This folder is a Unity Package Manager sample for __DISPLAY_NAME__.

Samples live under `Samples~` (note the trailing `~`) so Unity ignores this
folder by default and it is never imported automatically with the package.
Users opt in from **Package Manager > __DISPLAY_NAME__ > Samples > Import**,
which copies this folder into their project's `Assets/Samples/` directory.

## What to put here

Add a minimal, runnable example that demonstrates the intended usage of the
package: a scene, a prefab, a small script, or a combination of these.
Keep it self-contained - it should not depend on anything outside this
sample folder besides the package itself.

## Adding more samples

To add another sample, create a sibling folder next to `BasicUsage/` and
register it in the `samples` array of `package.json`:

```json
{
  "displayName": "Another Sample",
  "description": "What it demonstrates.",
  "path": "Samples~/AnotherSample"
}
```
