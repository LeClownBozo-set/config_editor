return {
    "mfussenegger/nvim-dap",
    config = function()
        local dap = require("dap")

        -- Configuration de l'adaptateur
        dap.adapters.gdb_m68k = {
            type = "executable",
            command = "gdb-multiarch",
            args = { "-i", "dap" }
        }

        -- Profil de débogage pour s'attacher à QEMU
        dap.configurations.asm = {
            {
                name = "Attacher à QEMU (M68k)",
                type = "gdb_m68k",
                request = "attach",
                target = "localhost:1234",
                program = function()
                    return vim.fn.expand("%:r")
                end,
                cwd = "${workspaceFolder}",
            },
        }
    end,
}
