-- On définit notre touche leader sur espace
vim.g.mapleader = " "

-- Raccourci pour la fonction set
local keymap = vim.keymap.set

-- on utilise ;; pour sortir du monde insertion
keymap("i", ";;", "<ESC>", { desc = "Sortir du mode insertion avec ;;" })

-- on efface le surlignage de la recherche
keymap("n", "<leader>nh", ":nohl<CR>", { desc = "Effacer le surlignage de la recherche" })

-- I déplace le texte sélectionné vers le haut en mode visuel (activé avec v)
keymap("v", "<S-i>", ":m .-2<CR>==", { desc = "Déplace le texte sélectionné vers le haut en mode visuel" })
-- K déplace le texte sélectionné vers le bas en mode visuel (activé avec v)
keymap("v", "<S-k>", ":m .+1<CR>==", { desc = "Déplace le texte sélectionné vers le bas en mode visuel" })

-- I déplace le texte sélectionné vers le haut en mode visuel bloc (activé avec V)
keymap("x", "<S-i>", ":move '<-2<CR>gv-gv", { desc = "Déplace le texte sélectionné vers le haut en mode visuel bloc" })
-- K déplace le texte sélectionné vers le bas en mode visuel (activé avec V)
keymap("x", "<S-k>", ":move '>+1<CR>gv-gv", { desc = "Déplace le texte sélectionné vers le bas en mode visuel bloc" })
-- Navigation entre les buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

keymap("n", "<C-h>", "<C-w>h", { desc = "Déplace le curseur dans la fenêtre de gauche" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Déplace le curseur dans la fenêtre du bas" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Déplace le curseur dans la fenêtre du haut" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Déplace le curseur dans la fenêtre droite" })
-- Compilation et Exécution Assembleur 68k (Touche F9)
keymap("n", "<F9>", function()
    local file = vim.fn.expand("%")
    local name = vim.fn.expand("%:r")

    -- Commande : Assemblage m68k -> Édition de liens m68k -> Exécution via qemu-m68k
    local cmd = string.format("!m68k-linux-gnu-as %s -o %s.o && m68k-linux-gnu-ld %s.o -o %s && qemu-m68k ./%s", file,
        name, name, name, name)

    vim.cmd(cmd)
end, { desc = "Compiler et exécuter M68k" })

-- Préparer le débogage M68k (Touche F10)
keymap("n", "<F10>", function()
    local file = vim.fn.expand("%")
    local name = vim.fn.expand("%:r")

    -- Compile avec -g, puis lance qemu avec -g 1234 (écoute sur le port 1234)
    local compile_cmd = string.format("m68k-linux-gnu-as -g %s -o %s.o && m68k-linux-gnu-ld %s.o -o %s", file, name, name,
        name)
    local run_cmd = string.format("qemu-m68k -g 1234 ./%s", name)

    -- Ouvre un terminal Neovim en bas de l'écran et lance les commandes
    vim.cmd("botright split | terminal " .. compile_cmd .. " && " .. run_cmd)

    print("Compilation OK. QEMU écoute sur le port 1234. Lance DapContinue !")
end, { desc = "Serveur QEMU M68k" })
