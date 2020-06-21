

function LookupInternetStormStatus()
local S, str

if lookup_counter % 60 == 0
then
S=stream.STREAM("https://isc.sans.edu/infocon.txt", "r")
if S ~= nil
then
	str=S:readln()
	S:close()
end

display_values["isc"]=TranslateColorName(str)..str.."~0"
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
