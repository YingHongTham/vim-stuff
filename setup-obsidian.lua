require("obsidian").setup({
	"obsidian-nvim/obsidian.nvim",
	dir = "C:\\Program Files\\Neovim\\share\\nvim\\runtime\\pack\\dist\\opt\\obsidian.nvim",
	dev = true,
	version = "*",	-- recommended, use latest release instead of latest commit
	lazy = true,
	ft = "markdown",
	-- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
	-- event = {
	--	 -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
	--	 -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
	--	 -- refer to `:h file-pattern` for more examples
	--	 "BufReadPre path/to/my-vault/*.md",
	--	 "BufNewFile path/to/my-vault/*.md",
	-- },
	dependencies = {
		-- Required.
		--"plenary.nvim",
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "learning",
				path = "~/vaults/learning",
			},
			{
				name = "work",
				path = "~/vaults/work",
			},
		},
		templates = {
			folder = "templates",
			date_format = "%Y.%m.%d",
			time_format = "%H:%M",
		},
		ui = {
			enable = false,
		},
	},
	vim.keymap.set("n", "<leader>on", ":ObsidianNew ", { desc = "Obsidian: Open new file" }),
	vim.keymap.set("n", "<leader>of", ":ObsidianFollowLink<cr>", { desc = "Obsidian: Follow link" }),
	vim.keymap.set("n", "<leader>ol", ":ObsidianLinks<cr>", { desc = "Obsidian: Show all links" }),
	vim.keymap.set("v", "<leader>oln", ":ObsidianLinkNew ", { desc = "Obsidian: Create new link" }),
	vim.keymap.set("n", "<leader>ow", ":ObsidianQuickSwitch<cr>", { desc = "Obsidian: Quick Switch to another note" }),
	vim.keymap.set("v", "<leader>ox", ":ObsidianExtractNote ", { desc = "Obsidian: Extract note and create new link" }),
	vim.keymap.set("n", "<leader>o/", ":ObsidianSearch<cr>", { desc = "Obsidian: Search vault" }),
	vim.keymap.set("v", "<leader>o/", "y:ObsidianSearch <C-R>\"<cr>", { desc = "Obsidian: Search vault" }),
})
