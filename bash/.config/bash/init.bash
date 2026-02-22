if [ -d "$HOME/.config/bash/config.d" ]; then
    for config_mod in "$HOME"/.config/bash/config.d/*; do
        . "$config_mod"
    done
fi

if [ -d "$HOME/.config/bash/functions.d" ]; then
   for function_mod in "$HOME"/.config/bash/functions.d/*; do
     . "$function_mod"
   done	   
fi

if [ -d "$HOME/.config/bash/completions.d" ]; then
   for completion_mod in "$HOME"/.config/bash/completions.d/*; do
     . "$completion_mod"
   done	   
fi


if [ -d "$HOME/.config/bash/path.d" ]; then
   for path_mod in "$HOME"/.config/bash/path.d/*; do
     . "$path_mod"
   done	   
fi

if [ -d "$HOME/.config/bash/aliases.d" ]; then
   for alias_mod in "$HOME"/.config/bash/aliases.d/*; do
     . "$alias_mod"
   done	   
fi

#############################################################
# Available themes are stored in $HOME/.config/bash/themes.d
# To enable an available theme copy or link the desired 
# theme file to ~/.config/bash/theme.bash
#############################################################
if [ -f "$HOME/.config/bash/theme.bash" ]; then
   . "$HOME/.config/bash/theme.bash"
fi

#############################################################
# Available prompts are stored in $HOME/.config/bash/prompts.d
# To enable an available prompt copy or link the desired 
# prompt file to ~/.config/bash/prompt.bash
#############################################################
if [ -f "$HOME/.config/bash/prompt.bash" ]; then
   . "$HOME/.config/bash/prompt.bash"
fi
