# zhuyin-pinyin.nvim

## Installation

Install the plugin with your preferred package manager, e.g., [folke/lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
return {
	"Willie169/zhuyin-pinyin.nvim",
	config = function()
		require("zhuyin-pinyin").setup()
	end
}
```

## Configuration

Default configuration:
```lua
require("zhuyin-pinyin"),setup({
	mappings = {
		zhuyin_to_pinyin = "<localleader>zp",
		pinyin_to_zhuyin = "<localleader>pz",
		zhuyin_to_zhuyin_key = "<localleader>zk",
		zhuyin_key_to_zhuyin = "<localleader>kz",
		pinyin_to_zhuyin_key = "<localleader>pk",
		zhuyin_key_to_pinyin = "<localleader>kp",
	},
})
```

