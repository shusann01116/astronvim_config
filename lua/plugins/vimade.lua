---@type LazySpec
return {
	"tadaa/vimade",
	event = "UIEnter",
	opts = {
		fadelevel = 0.4,
		enablefocusfading = true,
		ncmode = "buffers",
		groupdiff = true,
		groupscrollbind = false,
		tint = {
			bg = { rgb = { 48, 48, 48 }, intensity = 0.5 },
		},
	},
}
