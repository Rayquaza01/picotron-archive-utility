--[[pod_format="raw",created="2024-03-15 13:58:36",modified="2025-02-03 15:20:49",revision=775]]
-- zip v1.0
-- by Arnaught

include("require.lua")
local DecompressGz = require("gz")
local ExtractTar = require("tar")

function _init()
	-- zip_file = fetch("/projects/zip/picotron-definitions-main.tar.gz")
	-- zip_file = fetch("/projects/zip/second.tar.gz")
	zip_file = fetch("/projects/zip/archive.tar.gz")
	-- zip_file = fetch("/projects/zip/combined.gz")
	--- @cast zip_file string

	files = {}

	for t in all(DecompressGz(zip_file)) do
		for f in all(ExtractTar(t.payload)) do
			add(files, f)
		end
	end
end

function _update()
end

function _draw()
	cls()
	for f in all(files) do
		print(string.format("%s: %s", f.name, pod(f.content)))
	end
end
