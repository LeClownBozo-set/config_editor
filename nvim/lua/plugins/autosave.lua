return {
    "okuuva/auto-save.nvim",
    cmd = "ASToggle",                       -- Permet de l'activer/désactiver avec :ASToggle
    event = { "InsertLeave", "TextChanged" }, -- Se déclenche quand on quitte l'insertion ou qu'on change le texte
    opts = {
        enabled = true,                     -- Activé au démarrage
        debounce_delay = 1000,              -- Sauvegarde après 1 seconde d'inactivité
        -- Tu peux ajouter des conditions ici (ex: ne pas sauvegarder certains types de fichiers)
    },
}
