# Starship theme per directory. Edit the table; themes are ~/.config/starship-<name>.toml.
# The last line is the default for everywhere else.
_starship_theme_for_dir() {
  local theme
  case "$PWD" in
    */reignition-studio/word-mage*)   theme=mage ;;
    */reignition-studio/tidal-front*) theme=naval ;;
    */plattnum-public-oss/cera*)      theme=gilt ;;
    *)                                theme=arcade ;;
  esac
  export STARSHIP_CONFIG="$HOME/.config/starship-${theme}.toml"
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _starship_theme_for_dir
_starship_theme_for_dir
