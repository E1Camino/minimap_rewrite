return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`minimap2` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("minimap2", {
			mod_script       = "scripts/mods/minimap2/minimap2",
			mod_data         = "scripts/mods/minimap2/minimap2_data",
			mod_localization = "scripts/mods/minimap2/minimap2_localization",
		})
	end,
	packages = {
		"resource_packages/minimap2/minimap2",
	},
}
