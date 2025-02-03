--[[pod_format="raw",created="2025-02-03 00:53:52",modified="2025-02-03 15:20:49",revision=637]]
--- https://www.lexaloffle.com/bbs/?tid=140981

__crc32_silent = false

local crc32_initialized = false
local crc32_table = {}

local function _crc32_init()
	local poly = 0xEDB88320
	for i = 0, 255 do
		local crc = i
		for j = 1, 8 do
			crc = (crc & 1) ~= 0 and (poly ~ (crc >> 1)) or (crc >> 1)
		end
   		crc32_table[i] = crc
	end
end

local function _crc32_str(str)
	if(not crc32_initialized) _crc32_init()

	local crc = 0xFFFFFFFF
	for i = 1, #str do
		local byte = string.byte(str, i)
		crc = crc32_table[(crc ~ byte) & 0xFF] ~ (crc >> 8)
	end
	return crc ~ 0xFFFFFFFF
end

local function crc32(data, file)
	if file == nil then
		file = (fstat(data) != "nil")
	end
	
	if file then
		local ftype = fstat(data)
		if ftype == "file" then
			data = fetch(data)
		elseif ftype == "folder" then
			-- recursively calculate. eek
			local subcrcs = {}
			for entry in all(ls(data)) do
				add(subcrcs, crc32(data.."/"..entry))
			end
			data = table.concat(subcrcs, ":")
		elseif ftype == nil then
			file = false
		else
			if(not __crc32_silent) printh("** crc32: cannot hash unknown fs type: "..ftype)
			return false
		end
	end
	
	return _crc32_str(data)
end

local function _crcs_edit(file, hash, mode)
	local hashes = {}
	
	if mode != "replace" then
		if fstat(file) == "file" then
			local orig = fetch(file)
			hashes = split(orig, ":", false)
		end
		
		if mode == "append" and count(hashes, hash) == 0 then
			add(hashes, hash)
		elseif mode == "delete" then
			while count(hashes, hash) > 0 do
				del(hashes, hash)
			end
		end
	else
		hashes = {hash}
	end
	
	if #hashes == 0 then
		rm(file)
	else
		store(file, table.concat(hashes, ":"))
	end
end

local function _crcs_version(target, dest, mode, dir)
	-- generate hashes of everything in target
	-- and write them into dest
	
	if(mode == "none") mode = "append"
	dir = dir or "/"

	for entry in all(ls(target..dir)) do
		local rpath = dir..entry
		local ftype = fstat(target..rpath)
		if ftype == "folder" then
			_crcs_version(target, dest, mode, rpath.."/")
		elseif ftype == "file" and rpath:sub(-5) != ".crcs" then
			local dst_ftype = fstat(dest..rpath)
			if dst_ftype == "file" then
				local target_hash = tostr(crc32(target..rpath, true))
				print(target_hash.." "..target..rpath)
				_crcs_edit(dest..rpath..".crcs", target_hash, mode)
			end
		end
	end
end

return crc32