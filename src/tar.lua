--[[pod_format="raw",created="2025-02-03 01:50:44",modified="2025-02-03 15:20:49",revision=652]]

--- @class __TAR
--- @field name string
--- @field mode string
--- @field uid string
--- @field gid string
--- @field size integer
--- @field mtime string
--- @field cksum string
--- @field typeflag string
--- @field linkname string
--- @field magic string
--- @field version string
--- @field uname string
--- @field gname string
--- @field devmajor string
--- @field devminor string
--- @field prefix string
--- @field content string
local __TAR = {}

--- Extracts files from a tape archive
--- @param tar string
--- @return __TAR[]
local function ExtractTar(tar)
	local offset = 0
	local blank_sectors = 0

	--- @type __TAR[]
	local files = {}

	-- file end is marked by 2 or more consecutive blank sectors
	while blank_sectors < 2 do
		local t = {}
		t.name = tar:sub(offset + 1, tar:find("\0", offset + 1) - 1)
		t.mode = tar:sub(offset + 101, offset + 108)
		t.uid = tar:sub(offset + 109, offset + 116)
		t.gid = tar:sub(offset + 116, offset + 124)
		-- size is in octal, and ends with \0
		t.size = tonumber(tar:sub(offset + 125, offset + 135), 8)
		t.mtime = date(nil, tar:sub(offset + 137, offset + 148))
		t.cksum = tar:sub(offset + 149, offset + 156)
		t.typeflag = tar:sub(offset + 157, offset + 157)
		t.linkname = tar:sub(offset + 158, tar:find("\0", offset + 158) - 1)
		t.magic = tar:sub(offset + 258, offset + 262)
		t.version = tar:sub(offset + 264, offset + 265)
		t.uname = tar:sub(offset + 266, tar:find("\0", offset + 266) - 1)
		t.gname = tar:sub(offset + 298, tar:find("\0", offset + 298) - 1)
		t.devmajor = tar:sub(offset + 330, offset + 337)
		t.devminor = tar:sub(offset + 338, offset + 345)
		t.prefix = tar:sub(offset + 346, tar:find("\0", offset + 346) - 1)

		--- @cast t __TAR

		if t.magic == "ustar" then
			t.content = tar:sub(offset + 513, offset + 513 + t.size - 1)
			add(files, t)

			-- sectors are 512 bytes in size
			-- round file size to next 512 byte boundary
			blank_sectors = 0
			offset += 512 + ceil(t.size / 512) * 512
		else
			blank_sectors += 1
			offset += 512
		end
	end

	return files
end

return ExtractTar
