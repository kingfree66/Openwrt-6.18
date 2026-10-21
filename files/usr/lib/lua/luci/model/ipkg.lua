-- luci.model.ipkg was removed upstream after the opkg -> apk migration,
-- but luci-app-autotimeset's model/cbi/autotimeset/base.lua still does
-- require "luci.model.ipkg" (leftover template line, no actual calls).
-- This empty stub keeps that require working so the page loads.
module("luci.model.ipkg", package.seeall)

function installed(pkg)
	return false
end

function status(pkg)
	return {}
end

function versions(pkg)
	return {}
end

function info(pkg)
	return {}
end

function compare_versions(ver1, comp, ver2)
	return false
end
