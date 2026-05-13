#!/usr/bin/env bash

set -euo pipefail
# set prompt
ln -s ${HOME}/.config/bash/prompts.d/starship.bash ${HOME}/.config/bash/prompt.bash

# set terminal theme
ln -s ${HOME}/.config/bash/themes.d/dracula.bash ${HOME}/.config/bash/theme.bash
