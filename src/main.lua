--[[pod_format="raw",created="2024-03-15 13:58:36",modified="2025-02-03 18:16:49",revision=778]]
-- zip v1.0
-- by Arnaught

include("require.lua")
local DecompressGz = require("gz")
local tar = require("tar")

cd(env().path)
local argv = env().argv or {}

function _init()
	if #argv > 0 then
		for arg in all(argv) do
			--- @cast arg string
			local ext = arg:ext()
			local basename = arg:basename()
			local name_no_ext = basename:sub(1, #basename - #ext - 1)

			if ext == "tar" then
				local tar_file = fetch(arg)
				--- @cast tar_file string

				local files = tar.ExtractTar(tar_file)

				local folder = fullpath(name_no_ext)
				mkdir(folder)

				tar.WriteTar(files, folder)
			elseif ext == "gz" then
			elseif ext == "tar.gz" then
				local zip = fetch(arg)
				--- @cast zip string
				local tar_file = DecompressGz(zip)[1].payload
				local files = tar.ExtractTar(tar_file)

				local folder = fullpath(name_no_ext)
				mkdir(folder)

				tar.WriteTar(files, folder)
			else
				notify("Unsupported format: " .. ext)
			end
		end

		exit()
	end

	-- zip_file = fetch("/projects/zip/picotron-definitions-main.tar.gz")
	-- zip_file = fetch("/projects/zip/second.tar.gz")
	-- zip_file = fetch("/projects/zip/archive.tar.gz")
	-- zip_file = fetch("/projects/zip/combined.gz")
	-- zip_file = fetch("https://github.com/Rayquaza01/picotron-definitions/archive/refs/heads/main.tar.gz")
	--- @cast zip_file string
end

function _update()
end

function _draw()
	cls()
end
