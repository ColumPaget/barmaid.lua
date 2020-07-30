

function LookupInternetStormStatus()
local S, str

if lookup_counter % 60 == 0
then
S=stream.STREAM("https://isc.sans.edu/infocon.txt", "r")
if S ~= nil
then
	str=S:readln()
	S:close()
	if strutil.strlen(str) > 0 then display_values["isc"]=str end
end

end

end


function InternetStormStatusInit(lookups, display_str)

if string.find(display_str, "$%(isc%)") ~= nil
then
	table.insert(lookups, LookupInternetStormStatus)
end

end


mod={}
mod.lookup=InternetStormStatusLookup
mod.init=InternetStormStatusInit
table.insert(lookup_modules, mod)
