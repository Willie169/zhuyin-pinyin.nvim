local M = {}

M.config = {
	mappings = {
		zhuyin_to_pinyin = "<M-z>p",
		pinyin_to_zhuyin = "<M-p>z",
		zhuyin_to_zhuyin_key = "<M-z>k",
		zhuyin_key_to_zhuyin = "<M-k>z",
		pinyin_to_zhuyin_key = "<M-p>k",
		zhuyin_key_to_pinyin = "<M-k>p",
	},
}

-- UTF-8 iterator, compatible with LuaJIT / Lua 5.1

local function utf8_chars(str)
	local i = 1
	local n = #str
	return function()
		if i > n then
			return nil
		end
		local c = str:byte(i)
		local len
		if c < 0x80 then
			len = 1
		elseif c < 0xE0 then
			len = 2
		elseif c < 0xF0 then
			len = 3
		elseif c < 0xF8 then
			len = 4
		else
			error("invalid UTF-8")
		end
		local char = str:sub(i, i + len - 1)
		i = i + len
		return char
	end
end

-- Zhuyin to Pinyin table

local initials = {
	["ㄅ"] = "b",
	["ㄆ"] = "p",
	["ㄇ"] = "m",
	["ㄈ"] = "f",
	["ㄉ"] = "d",
	["ㄊ"] = "t",
	["ㄋ"] = "n",
	["ㄌ"] = "l",
	["ㄍ"] = "g",
	["ㄎ"] = "k",
	["ㄏ"] = "h",
	["ㄐ"] = "j",
	["ㄑ"] = "q",
	["ㄒ"] = "x",
	["ㄓ"] = "zh",
	["ㄔ"] = "ch",
	["ㄕ"] = "sh",
	["ㄖ"] = "r",
	["ㄗ"] = "z",
	["ㄘ"] = "c",
	["ㄙ"] = "s",
}

local finals = {
	["ㄚ"] = "a",
	["ㄛ"] = "o",
	["ㄜ"] = "e",
	["ㄝ"] = "ê",
	["ㄞ"] = "ai",
	["ㄟ"] = "ei",
	["ㄠ"] = "ao",
	["ㄡ"] = "ou",
	["ㄢ"] = "an",
	["ㄣ"] = "en",
	["ㄤ"] = "ang",
	["ㄥ"] = "eng",
	["ㄦ"] = "er",
	["ㄧ"] = "i",
	["ㄨ"] = "u",
	["ㄩ"] = "ü",
}

local compounds = {
	["ㄧㄚ"] = "ia",
	["ㄧㄛ"] = "io",
	["ㄧㄝ"] = "ie",
	["ㄧㄞ"] = "iai",
	["ㄧㄠ"] = "iao",
	["ㄧㄡ"] = "iu",
	["ㄧㄢ"] = "ian",
	["ㄧㄣ"] = "in",
	["ㄧㄤ"] = "iang",
	["ㄧㄥ"] = "ing",
	["ㄨㄚ"] = "ua",
	["ㄨㄛ"] = "uo",
	["ㄨㄞ"] = "uai",
	["ㄨㄟ"] = "ui",
	["ㄨㄢ"] = "uan",
	["ㄨㄣ"] = "un",
	["ㄨㄤ"] = "uang",
	["ㄨㄥ"] = "ong",
	["ㄩㄝ"] = "üe",
	["ㄩㄢ"] = "üan",
	["ㄩㄣ"] = "ün",
	["ㄩㄥ"] = "iong",
}

local special = {
	["ㄧ"] = "yi",
	["ㄧㄚ"] = "ya",
	["ㄧㄛ"] = "yo",
	["ㄧㄝ"] = "ye",
	["ㄧㄞ"] = "yai",
	["ㄧㄠ"] = "yao",
	["ㄧㄡ"] = "you",
	["ㄧㄢ"] = "yan",
	["ㄧㄣ"] = "yin",
	["ㄧㄤ"] = "yang",
	["ㄧㄥ"] = "ying",
	["ㄨ"] = "wu",
	["ㄨㄚ"] = "wa",
	["ㄨㄛ"] = "wo",
	["ㄨㄞ"] = "wai",
	["ㄨㄟ"] = "wei",
	["ㄨㄢ"] = "wan",
	["ㄨㄣ"] = "wen",
	["ㄨㄤ"] = "wang",
	["ㄨㄥ"] = "weng",
	["ㄩ"] = "yu",
	["ㄩㄝ"] = "yue",
	["ㄩㄢ"] = "yuan",
	["ㄩㄣ"] = "yun",
	["ㄩㄥ"] = "yong",
	["ㄓ"] = "zhi",
	["ㄔ"] = "chi",
	["ㄕ"] = "shi",
	["ㄖ"] = "ri",
	["ㄗ"] = "zi",
	["ㄘ"] = "ci",
	["ㄙ"] = "si",
	["ㄐㄧ"] = "ji",
	["ㄑㄧ"] = "qi",
	["ㄒㄧ"] = "xi",
	["ㄐㄩ"] = "ju",
	["ㄑㄩ"] = "qu",
	["ㄒㄩ"] = "xu",
	["ㄐㄩㄝ"] = "jue",
	["ㄑㄩㄝ"] = "que",
	["ㄒㄩㄝ"] = "xue",
	["ㄐㄩㄢ"] = "juan",
	["ㄑㄩㄢ"] = "quan",
	["ㄒㄩㄢ"] = "xuan",
	["ㄐㄩㄣ"] = "jun",
	["ㄑㄩㄣ"] = "qun",
	["ㄒㄩㄣ"] = "xun",
	["ㄐㄩㄥ"] = "jiong",
	["ㄑㄩㄥ"] = "qiong",
	["ㄒㄩㄥ"] = "xiong",
}

local zhuyin_to_tone = {
	[" "] = 1,
	["ˊ"] = 2,
	["ˇ"] = 3,
	["ˋ"] = 4,
	["˙"] = 5,
}

-- Pinyin to Zhuyin table

local pinyin_to_zhuyin = {}

for z, p in pairs(special) do
	pinyin_to_zhuyin[p] = z
end

for z, p in pairs(finals) do
	pinyin_to_zhuyin[p] = z
end

for z, p in pairs(compounds) do
	pinyin_to_zhuyin[p] = z
end

for iz, ip in pairs(initials) do
	for fz, fp in pairs(finals) do
		pinyin_to_zhuyin[ip .. fp] = iz .. fz
	end
	for fz, fp in pairs(compounds) do
		pinyin_to_zhuyin[ip .. fp] = iz .. fz
	end
end

local jqx = {
	["j"] = "ㄐ",
	["q"] = "ㄑ",
	["x"] = "ㄒ",
}

for p, z in pairs(jqx) do
	pinyin_to_zhuyin[p .. "u"] = z .. "ㄩ"
	pinyin_to_zhuyin[p .. "ue"] = z .. "ㄩㄝ"
	pinyin_to_zhuyin[p .. "uan"] = z .. "ㄩㄢ"
	pinyin_to_zhuyin[p .. "un"] = z .. "ㄩㄣ"
	pinyin_to_zhuyin[p .. "iong"] = z .. "ㄩㄥ"
end

local tone_to_zhuyin = {}

for z, t in pairs(zhuyin_to_tone) do
	tone_to_zhuyin[t] = z
end

-- Zhuyin syllable table

local zhuyin_syllables = {}

local function add_syllable(z)
	zhuyin_syllables[z] = true
end

for z in pairs(special) do
	add_syllable(z)
end

for iz in pairs(initials) do
	for fz in pairs(finals) do
		add_syllable(iz .. fz)
	end

	for fz in pairs(compounds) do
		add_syllable(iz .. fz)
	end
end

for z in pairs(special) do
	add_syllable(z)
end

-- Zhuyin to Zhuyin key table

local zhuyin_to_key = {
	["ㄅ"] = "1",
	["ㄆ"] = "q",
	["ㄇ"] = "a",
	["ㄈ"] = "z",
	["ㄉ"] = "2",
	["ㄊ"] = "w",
	["ㄋ"] = "s",
	["ㄌ"] = "x",
	["ㄍ"] = "e",
	["ㄎ"] = "d",
	["ㄏ"] = "c",
	["ㄐ"] = "r",
	["ㄑ"] = "f",
	["ㄒ"] = "v",
	["ㄓ"] = "5",
	["ㄔ"] = "t",
	["ㄕ"] = "g",
	["ㄖ"] = "b",
	["ㄗ"] = "y",
	["ㄘ"] = "h",
	["ㄙ"] = "n",
	["ㄧ"] = "u",
	["ㄨ"] = "j",
	["ㄩ"] = "m",
	["ㄚ"] = "8",
	["ㄛ"] = "i",
	["ㄜ"] = "k",
	["ㄝ"] = ",",
	["ㄞ"] = "9",
	["ㄟ"] = "o",
	["ㄠ"] = "l",
	["ㄡ"] = ".",
	["ㄢ"] = "0",
	["ㄣ"] = "p",
	["ㄤ"] = ";",
	["ㄥ"] = "/",
	["ㄦ"] = "-",
	["ˇ"] = "3",
	["ˋ"] = "4",
	["ˊ"] = "6",
	["˙"] = "7",
}

-- Zhuyin key to Zhuyin table

local key_to_zhuyin = {}

for zhuyin, key in pairs(zhuyin_to_key) do
	key_to_zhuyin[key] = zhuyin
end

-- convert

local function zhuyin_syllable_to_pinyin(zhuyin)
	local tone = 1
	for char in utf8_chars(zhuyin) do
		if zhuyin_to_tone[char] then
			tone = zhuyin_to_tone[char]
			break
		end
	end
	local plain = {}
	for char in utf8_chars(zhuyin) do
		if not zhuyin_to_tone[char] then
			plain[#plain + 1] = char
		end
	end
	local z = table.concat(plain)
	local pinyin = special[z]
	if not pinyin then
		local chars = {}
		for char in utf8_chars(z) do
			chars[#chars + 1] = char
		end
		local initial = ""
		local final = z
		if initials[chars[1]] then
			initial = initials[chars[1]]
			final = z:sub(#chars[1] + 1)
		end
		final = compounds[final] or finals[final]
		if final then
			pinyin = initial .. final
		end
	end
	if not pinyin then
		return nil
	end
	return pinyin .. tostring(tone)
end

local function parse_zhuyin(str)
	local chars = {}
	for char in utf8_chars(str) do
		chars[#chars + 1] = char
	end
	local result = {}
	local i = 1
	while i <= #chars do
		local found = nil
		for j = #chars, i, -1 do
			local candidate = table.concat(chars, "", i, j)
			if zhuyin_syllables[candidate] then
				if j < #chars and zhuyin_to_tone[chars[j + 1]] then
					candidate = candidate .. chars[j + 1]
					j = j + 1
				end
				found = candidate
				i = j + 1
				break
			end
		end
		if not found then
			result[#result + 1] = chars[i]
			i = i + 1
		else
			result[#result + 1] = found
		end
	end
	return result
end

function M.zhuyin_to_pinyin(str)
	local syllables = parse_zhuyin(str)
	local result = {}
	for _, syllable in ipairs(syllables) do
		local pinyin = zhuyin_syllable_to_pinyin(syllable)
		if pinyin then
			result[#result + 1] = pinyin
		else
			result[#result + 1] = syllable
		end
	end
	return table.concat(result)
end

local function pinyin_syllable_to_zhuyin(pinyin)
	pinyin = pinyin:lower()
	local tone = tonumber(pinyin:match("([1-5])$"))
	if not tone then
		return nil, "Pinyin must end with tone number 1-5"
	end
	local plain = pinyin:sub(1, -2)
	local z = pinyin_to_zhuyin[plain]
	if not z then
		return nil, "unknown Pinyin zhuyin: " .. plain
	end
	return z .. tone_to_zhuyin[tone]
end

local function parse_pinyin(str)
	local result = {}
	local i = 1
	while i <= #str do
		if not str:sub(i, i):match("[a-zA-Z]") then
			result[#result + 1] = str:sub(i, i)
			i = i + 1
		else
			local found = nil
			for len = 6, 1, -1 do
				local candidate = str:sub(i, i + len)
				if candidate:match("^[a-zA-Z]+[1-5]$") then
					local plain = candidate:sub(1, -2)
					if pinyin_to_zhuyin[plain] then
						found = candidate
						break
					end
				end
			end
			if found then
				result[#result + 1] = found
				i = i + #found
			else
				result[#result + 1] = str:sub(i, i)
				i = i + 1
			end
		end
	end
	return result
end

function M.pinyin_to_zhuyin(str)
	local syllables = parse_pinyin(str)
	local result = {}
	for _, syllable in ipairs(syllables) do
		local zhuyin = pinyin_syllable_to_zhuyin(syllable)
		if zhuyin then
			result[#result + 1] = zhuyin
		else
			result[#result + 1] = syllable
		end
	end
	return table.concat(result)
end

function M.zhuyin_to_zhuyin_key(str)
	local result = {}
	for char in utf8_chars(str) do
		result[#result + 1] = zhuyin_to_key[char] or char
	end
	return table.concat(result)
end

function M.zhuyin_key_to_zhuyin(str)
	local result = {}
	for i = 1, #str do
		local char = str:sub(i, i)
		result[#result + 1] = key_to_zhuyin[char:lower()] or char
	end
	return table.concat(result)
end

function M.pinyin_to_zhuyin_key(str)
	local zhuyin, err = M.pinyin_to_zhuyin(str)
	if not zhuyin then
		return nil, err
	end
	return M.zhuyin_to_zhuyin_key(zhuyin)
end

function M.zhuyin_key_to_pinyin(str)
	return M.zhuyin_to_pinyin(M.zhuyin_key_to_zhuyin(str))
end

function M.transform_selection(func)
	vim.cmd('normal! gv"xd')
	local text = vim.fn.getreg("x")
	local transformed, err = func(text)
	if not transformed then
		transformed = text
	end
	vim.fn.setreg("x", transformed, "c")
	vim.cmd('normal! "xp')
	return text
end

function M.zhuyin_to_pinyin_selection()
	return M.transform_selection(M.zhuyin_to_pinyin)
end

function M.pinyin_to_zhuyin_selection()
	return M.transform_selection(M.pinyin_to_zhuyin)
end

function M.zhuyin_to_zhuyin_key_selection()
	return M.transform_selection(M.zhuyin_to_zhuyin_key)
end

function M.zhuyin_key_to_zhuyin_selection()
	return M.transform_selection(M.zhuyin_key_to_zhuyin)
end

function M.pinyin_to_zhuyin_key_selection()
	return M.transform_selection(M.pinyin_to_zhuyin_key)
end

function M.zhuyin_key_to_pinyin_selection()
	return M.transform_selection(M.zhuyin_key_to_pinyin)
end

M.setup = function(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	if M.config.mappings.zhuyin_to_pinyin then
		vim.keymap.set(
			"x",
			M.config.mappings.zhuyin_to_pinyin,
			M.zhuyin_to_pinyin_selection,
			{ desc = "zhuyin to pinyin" }
		)
	end
	if M.config.mappings.pinyin_to_zhuyin then
		vim.keymap.set(
			"x",
			M.config.mappings.pinyin_to_zhuyin,
			M.pinyin_to_zhuyin_selection,
			{ desc = "pinyin to zhuyin" }
		)
	end
	if M.config.mappings.zhuyin_to_zhuyin_key then
		vim.keymap.set(
			"x",
			M.config.mappings.zhuyin_to_zhuyin_key,
			M.zhuyin_to_zhuyin_key_selection,
			{ desc = "zhuyin to zhuyin key" }
		)
	end
	if M.config.mappings.zhuyin_key_to_zhuyin then
		vim.keymap.set(
			"x",
			M.config.mappings.zhuyin_key_to_zhuyin,
			M.zhuyin_key_to_zhuyin_selection,
			{ desc = "zhuyin key to zhuyin" }
		)
	end
	if M.config.mappings.pinyin_to_zhuyin_key then
		vim.keymap.set(
			"x",
			M.config.mappings.pinyin_to_zhuyin_key,
			M.pinyin_to_zhuyin_key_selection,
			{ desc = "pinyin to zhuyin key" }
		)
	end
	if M.config.mappings.zhuyin_key_to_pinyin then
		vim.keymap.set(
			"x",
			M.config.mappings.zhuyin_key_to_pinyin,
			M.zhuyin_key_to_pinyin_selection,
			{ desc = "zhuyin key to pinyin" }
		)
	end
end

return M
