return {
    "mfussenegger/nvim-dap",
    dependencies = {
        -- L'interface graphique pour le débogueur
        "rcarriga/nvim-dap-ui",
        -- Dépendance requise par dap-ui
        "nvim-neotest/nvim-nio",
        -- Le pont entre Mason et DAP
        "jay-babu/mason-nvim-dap.nvim",
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        -- 1. Configuration de Mason-DAP
        require("mason-nvim-dap").setup({
            ensure_installed = { "codelldb" }, -- Installe automatiquement le débogueur C/C++
            handlers = {},               -- Le fait de laisser vide dit à mason-nvim-dap de configurer codelldb tout seul avec les bons chemins !
        })

        -- 2. Configuration de l'interface graphique (DAP UI)
        dapui.setup()

        -- 3. Ouverture et fermeture automatique de l'interface
        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end

        -- 4. Raccourcis clavier (Keymaps)
        -- Appuie sur <Espace>+b pour mettre un point d'arrêt (breakpoint)
        vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = "DAP: Toggle Breakpoint" })

        -- F5 pour lancer ou continuer le débogage
        vim.keymap.set('n', '<F5>', dap.continue, { desc = "DAP: Continue" })

        -- F10 pour passer à la ligne suivante (Step Over)
        vim.keymap.set('n', '<F10>', dap.step_over, { desc = "DAP: Step Over" })

        -- F11 pour rentrer dans une fonction (Step Into)
        vim.keymap.set('n', '<F11>', dap.step_into, { desc = "DAP: Step Into" })

        -- F12 pour sortir de la fonction courante (Step Out)
        vim.keymap.set('n', '<F12>', dap.step_out, { desc = "DAP: Step Out" })
    end,
}
