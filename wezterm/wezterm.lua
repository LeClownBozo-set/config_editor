-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 150
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.window_close_confirmation = 'NeverPrompt'
config.font_size = 14.5
config.color_scheme = 'Sakura'
config.font = wezterm.font 'Fira Code Nerd Font'
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.85
config.window_padding = {
    left = 5,
    right = 5,
    top = 5,
    bottom = 5,
}
config.hide_tab_bar_if_only_one_tab = true
-- Finally, return the configuration to wezterm:
-- On désactive le style par défaut pour utiliser nos propres couleurs
config.use_fancy_tab_bar = false
config.tab_max_width = 34
-- 1. Le dégradé Sakura pour l'arrière-plan de la fenêtre
config.window_background_gradient = {
    orientation = 'Vertical',
    colors = {
        '#2a1c24', -- Haut : sombre avec une légère teinte rosée (idéal pour la lisibilité)
        '#4f2c3e', -- Milieu : un prune/rose poudré sombre
        '#8c4a6b', -- Bas : un rose Sakura plus assumé
    },
    interpolation = 'CatmullRom',
    blend = 'Oklab',
}

-- 2. Les couleurs des onglets harmonisées avec le dégradé
config.colors = {
    tab_bar = {
        -- Fond totalement transparent pour voir le dégradé passer à travers
        background = 'rgba(0, 0, 0, 0)',

        -- L'onglet sur lequel tu travailles (Rose clair, texte sombre)
        active_tab = {
            bg_color = '#ffb8d1',
            fg_color = '#2a1c24',
        },

        -- Les onglets en arrière-plan (Prune sombre, texte rose)
        inactive_tab = {
            bg_color = '#2a1c24',
            fg_color = '#ffb8d1',
        },

        -- Quand tu passes ta souris sur un onglet inactif
        inactive_tab_hover = {
            bg_color = '#4f2c3e',
            fg_color = '#ffffff',
        },
    },
}



config.keys = {
    {
        key = 'w',
        mods = 'CTRL|SHIFT',
        action = wezterm.action.CloseCurrentTab { confirm = false },
    },
    {
        key = 'x',
        mods = 'CTRL|SHIFT',
        action = wezterm.action.CloseCurrentPane { confirm = false },
    },
    {
        key = 'p',
        mods = 'ALT',
        action = wezterm.action.InputSelector {
            title = "Choisir un projet",
            choices = {
                { label = "Alea-web",  id = wezterm.home_dir .. "/Bureau/AleasAdventure/Alea-sAdventuresWebSite/" },
                { label = "Alea-game", id = "/home/ehrhardtvictor/Bureau/AleasAdventure/Alea-sAdventuresGame/" },
            },
            action = wezterm.action_callback(function(window, pane, id, label)
                if id then
                    window:perform_action(wezterm.action.SpawnCommandInNewTab { cwd = id }, pane)
                end
            end),
        },
    },
}

return config
