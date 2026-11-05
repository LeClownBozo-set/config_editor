require("core")
require("config.lazy")
vim.opt.swapfile = true
vim.opt.directory = vim.fn.stdpath("data") .. "/swap//" -- Le // à la fin évite les conflits de noms
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo//"
