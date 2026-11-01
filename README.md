# starship-themes

Powerline prompts for [Starship](https://starship.rs), plus matching status lines for
Claude Code. All of them need a [Nerd Font](https://www.nerdfonts.com/); they were built
and checked against Hack Nerd Font v3.

## Themes

Six palettes share one layout, derived from the Viking theme in
[tr3ss/starship-themes](https://github.com/tr3ss/starship-themes): ice-shaped separators,
a project badge, a repo-aware directory, git branch, status, rebase/merge state and line
metrics, runtime badges, the clock, and the prompt character on its own line.

| Theme | Ramp |
|---|---|
| `viking` | teal, the original palette |
| `druid` | forest green to mint |
| `mage` | deep violet to lavender |
| `gilt` | bronze to gold |
| `ember` | wine to rose |
| `naval` | dark navy to sky |

Three more are their own layouts:

| Theme | Look |
|---|---|
| `arcade` | 8-bit powerline: pixel stair-step separators, synthwave gradient, `▓▒░` cursor |
| `neon` | thin box-drawing frame, neon text, rail across to the clock |
| `hud` | dark glass panels with slanted edges, neon readouts, fading chevron cursor |

## Install

```sh
mkdir -p ~/.config
cp themes/mage.toml ~/.config/starship.toml
```

Or keep them all and point Starship at one:

```sh
cp themes/*.toml ~/.config/
export STARSHIP_CONFIG=~/.config/arcade.toml
```

### One theme per directory

Starship re-reads `STARSHIP_CONFIG` on every prompt, so a `chpwd` hook can switch themes
as you `cd`. `zsh-theme-per-directory.zsh` is the hook; it expects the themes at
`~/.config/starship-<name>.toml`. Edit the `case` table, then source it from `~/.zshrc`.

```sh
for f in themes/*.toml; do cp "$f" ~/.config/starship-$(basename "$f"); done
cat zsh-theme-per-directory.zsh >> ~/.zshrc
```

### Project badge

Every theme has a `[custom.project]` module at the bottom that prints a glyph per project
by matching the current path, with the Apple logo as the fallback. Add a line to its
`case` block for each of your projects.

## Claude Code status line

`claude-code/` has the same bar for Claude Code's status line, in the viking and druid
palettes. Install one and point `~/.claude/settings.json` at it:

```sh
cp claude-code/statusline-druid.sh ~/.claude/statusline-command.sh
```

```json
"statusLine": {
  "type": "command",
  "command": "bash /Users/you/.claude/statusline-command.sh"
}
```

It needs `jq`.

## Credits

Layout and the Viking palette from [tr3ss/starship-themes](https://github.com/tr3ss/starship-themes).
