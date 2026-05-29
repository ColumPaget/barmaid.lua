-- This module looks up 'cyber attack' status from the Internet Storm Center at isc.sans.edu
-- use it by adding $(isc) to your display string
-- there are three levels
-- green: situation normal
-- yellow: raised risk of attack activity
-- red: cyber armageddon

mod={}

-- module init function, setup module and insert it into module table
mod.init=function(self, lookups, display_str)

if string.find(display_str, "$%(isc%)") ~= nil
then
	updater:add_mod(self)
end

end


-- module lookup function, do the actual looking up and insert the result
-- into the 'display_values' table
mod.lookup=function(self)
local S, str

S=stream.STREAM("https://isc.sans.edu/infocon.txt", "r")
if S ~= nil
then
	str=S:readln()
	S:close()

	if strutil.strlen(str) > 0 then print("isc=" .. str) end
end

end

table.insert(lookup_modules, mod)

