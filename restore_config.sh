#!/bin/bash
rsync -av --delete ~/config_editor/nvim/  ~/.config/nvim/ 
rsync -av --delete ~/config_editor/wezterm/ ~/.config/wezterm/ 
rsync -av --delete ~/config_editor/yazi/ ~/.config/yazi/ 
