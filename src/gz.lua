--[[pod_format="raw",created="2025-02-03 01:01:38",modified="2025-02-03 15:20:49",revision=644]]
local LibDeflate = require("LibDeflate")
local crc32 = require("crc32")

local FHCRC = 0x02
local FEXTRA = 0x04
local FNAME = 0x08
local FCOMMENT = 0x10

--- @class __GZIP
--- @field magic_number string
--- @field compression_method string
--- @field header_flags integer
--- @field mtime string
--- @field compression_flags string
--- @field os_id string
--- @field extra_field? string
--- @field original_name? string
--- @field comment? string
--- @field header_crc? integer
--- @field payload string
--- @field crc integer
--- @field size integer
local __GZIP = {}

--- Reads a gzip string and decompresses it. Multiple gzip strings can be combined together
--- @param zip string
--- @return __GZIP[]
local function DecompressGz(zip)
	local offset = zip:find("\031\139\008", 1) - 1

	--- @type __GZIP[]
	local unzipped = {}

	while offset < (#zip - 1) do
		local zip_end = #zip
		local next_end = zip:find("\031\139\008", offset + 3)
		if next_end then
			zip_end = next_end - 1
		end

		local magic_number = zip:sub(offset + 1, offset + 2)
		local compression_method = zip:sub(offset + 3, offset + 3)
		local header_flags = string.unpack("B", zip:sub(offset + 4, offset + 4))
		local mtime = string.unpack("<I4", zip:sub(offset + 5, offset + 8))
		local compression_flags = zip:sub(offset + 9, offset + 9)
		local os_id = zip:sub(offset + 10, offset + 10)

		local extra_field
		local original_name
		local comment
		local header_crc

		offset += 10

		if magic_number ~= "\031\139" and compression_method ~= "\008" then
			printh("Data is not in gzip format")
		else
			if (header_flags & FEXTRA) == FEXTRA then
				local extra_size = string.unpack("<I2", zip:sub(offset + 1, offset + 2))
				extra_field = zip:sub(offset + 3, offset + 3 + extra_size)
				offset += 3 + extra_size
			end

			if (header_flags & FNAME) == FNAME then
				original_name = zip:sub(offset + 1, zip:find("\0", offset + 1) - 1)
				offset += 1 + #original_name
			end

			if (header_flags & FCOMMENT) == FCOMMENT then
				comment = zip:sub(offset + 1, zip:find("\0", offset + 1) - 1)
				offset += 1 + #comment
			end

			-- todo verify crc16?
			if (header_flags & FHCRC) == FHCRC then
				header_crc = string.unpack("<I2", zip:sub(offset + 1, offset + 2))
				offset += 2
			end

			local payload = zip:sub(offset + 1, zip_end - 8)
			local expected_crc32 = string.unpack("<I4", zip:sub(zip_end - 7, zip_end - 4))
			local size = string.unpack("<I4", zip:sub(zip_end - 3, zip_end))

			local uncompressed = LibDeflate:DecompressDeflate(payload)
			local calc_crc32 = crc32(uncompressed, false)

			if calc_crc32 ~= expected_crc32 then
				printh(("CRC32 mismatch! Expected %d, got %d"):format(expected_crc32, calc_crc32))
			else
				add(unzipped, {
					magic_number = magic_number,
					compression_method = compression_method,
					header_flags = header_flags,
					mtime = date(nil, mtime),
					compression_flags = compression_flags,
					os_id = os_id,
					extra_field = extra_field,
					original_name = original_name,
					comment = comment,
					header_crc = header_crc,
					payload = uncompressed,
					crc = expected_crc32,
					size = size
				})
			end
		end

		offset = zip_end
	end

	return unzipped
end

return DecompressGz
