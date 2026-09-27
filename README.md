
# **ADDON_TITLE**

![GitHub License](https://img.shields.io/github/license/yak3d/wow-your-chronicle?style=for-the-badge)

<!-- Uncomment once the addon has a CurseForge project ID:
![CurseForge Game Versions](https://img.shields.io/curseforge/game-versions/PROJECT_ID?style=for-the-badge)
-->

**ADDON_NOTES**

## Usage

| Command                   | Description                 |
| ------------------------- | --------------------------- |
| `/yc`                     | Open or close the journal   |
| `/yc new`                 | Open the journal and start writing |
| `/yc log`                 | List the deeds recorded today |
| `/yc config`              | Open the settings panel     |
| `/yc help`                | Show available commands     |

## Settings

You can find the settings and their descriptions in Settings --> AddOns --> **ADDON_TITLE**.

## Development

If you want to develop on this addon, you can use the `Makefile` to easily install it.
Run `make help` to see every target and the paths it resolved.

### Installation

#### Simple Install

If you're on Windows, Mac or Linux with Faugus this will likely "just work":

```shell
make install
```

#### Complex Install

If the path can't be found, then you can specify it with the `WOW_DIR` variable.
It is cached in `.wow_path` so you only need to pass it once:

```shell
make install WOW_DIR="/path/to/World of Warcraft"
```

To target a different game flavor, override `FLAVOR` (default: `_classic_beta_`):

```shell
make install FLAVOR=_classic_beta_
```

### Uninstallation

Same commands as above, just replace `install` with `uninstall`.
`make reset` forgets the cached `WOW_DIR`.

### Linting

```shell
make lint
```

Runs [luacheck](https://github.com/lunarmodules/luacheck) with the bundled
`.luacheckrc` if it is installed (`luarocks install luacheck`).

### Releasing

Pushing a tag runs the [BigWigs packager](https://github.com/BigWigsMods/packager),
which attaches a zip to a GitHub release and, if `## X-Curse-Project-ID` is set
in the TOC and a `CF_API_KEY` repository secret exists, uploads to CurseForge.

```shell
git tag 1.0.0 && git push origin 1.0.0
```
# wow-addon-template
