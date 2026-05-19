# vim-stuff

vimrc, some config files, ftplugin files

# Neovim plugins
tired of lazy.nvim shit, package manager shit
just going to install things "manually"
(see https://vonheikemen.github.io/devlog/tools/installing-neovim-plugins-without-a-plugin-manager/)

basic procedure:
download/git-clone the repo of the plugin to
  "C:\Program Files\Neovim\share\nvim\runtime\pack\dist\opt"
(this folder is found with :set packpath?, then looked for ..\pack\dist\opt;
see https://neovim.io/doc/user/pack/)
(there is a sibling folder ...\start, which would load the plugin always, opt = optional)

then when want to use the plugin, load with
:packadd <plugin name>
and then call require("plugin name").setup({...})

for obsidian, I put the setup file in the vault folder, "setup-obsidian.lua",
so after packadd, load this file with
:luafile setup-obsidian.lua
(seems epwalsh/obsidian.nvim doesn't work, doesn't have the plugin folder,
maybe cos it requires use of some package manager;
using the forked version https://github.com/obsidian-nvim/obsidian.nvim)

note that if some lua file loaded once and failed, must close nvim and start again...
