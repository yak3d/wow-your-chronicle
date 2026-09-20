<!-- template:begin -->

# wow-addon-template

Starter template for a World of Warcraft addon targeting **Retail** or
**WoW Forever** (`_classic_beta_`). Ships a Makefile that symlinks the addon
into your game install, a luacheck config, a BigWigs packager release
workflow, and a minimal addon (chat print helper, SavedVariables with
defaults and migration hook, Settings panel, slash command, locale table).

## Usage

1. Create a repo from this template (or clone it) and `cd` into it.
2. Run init once:

   ```shell
   make init NAME=MyAddon FLAVOR=retail          # or FLAVOR=forever
   ```

   Optional variables: `TITLE="My Addon"`, `AUTHOR=Yak`, `SLASH=ma`,
   `NOTES="What it does"`, `REPO=my-addon`, `GITHUB_USER=yak3d`.

3. Commit the result. This block and the `init` target are removed by init.

| Variable            | Token                                                                              | Default                                           |
| ------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------- |
| `NAME` (required)   | `__ADDON_NAME__` folder, TOC, `SavedVariables`                                     | -                                                 |
| `FLAVOR` (required) | `__INTERFACE__` (`120100` / `16001`), `__FLAVOR__` (`_retail_` / `_classic_beta_`) | -                                                 |
| `TITLE`             | `__ADDON_TITLE__`                                                                  | `NAME`                                            |
| `SLASH`             | `__ADDON_SLASH__`                                                                  | lower-cased `NAME`                                |
| `NOTES`             | `__ADDON_NOTES__`                                                                  | `<TITLE> for World of Warcraft.`                  |
| `AUTHOR`            | `__AUTHOR__`                                                                       | `git config user.name`, then `$USER`              |
| `REPO`              | `__REPO_NAME__`                                                                    | from the `origin` remote, else the directory name |
| `GITHUB_USER`       | `__GITHUB_USER__`                                                                  | from the `origin` remote, else `yak3d`            |

`__ADDON_UPPER__` and `__ADDON_LOWER__` are derived from `NAME`.

<!-- template:end -->

# **ADDON_TITLE**

![GitHub License](https://img.shields.io/github/license/__GITHUB_USER__/__REPO_NAME__?style=for-the-badge)

<!-- Uncomment once the addon has a CurseForge project ID:
![CurseForge Game Versions](https://img.shields.io/curseforge/game-versions/PROJECT_ID?style=for-the-badge)
-->

**ADDON_NOTES**

## Usage

| Command                   | Description                 |
| ------------------------- | --------------------------- |
| `/__ADDON_SLASH__`        | Show available commands     |
| `/__ADDON_SLASH__ config` | Open the settings panel     |
| `/__ADDON_SLASH__ toggle` | Enable or disable the addon |

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

To target a different game flavor, override `FLAVOR` (default: `__FLAVOR__`):

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
