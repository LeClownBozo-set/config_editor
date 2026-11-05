#!/bin/bash
rsync -av --delete ~/.config/nvim/ ~/config_editor/nvim/ 
rsync -av --delete ~/.config/wezterm/ ~/config_editor/wezterm/ 
rsync -av --delete ~/.config/yazi/ ~/config_editor/yazi/
