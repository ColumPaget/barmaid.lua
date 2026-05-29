-- This module looks up ip addresses in DNS blocklist services. It is activated by an entry of the form:
--
-- $(dbl:8.8.8.8)
--
-- in the display string (in this case the ip to lookup is 8.8.8.8). If this ip is in any blacklist, then the string 'yes' is 
-- returned, otherwise the string 'no' is returned


--service list. You can add extra services here
proc=nil

mod_dbl={

interpret_response=function(self, service, str)

if strutil.strlen(str) == 0 then return false end

if string.sub(str, 1, 12) == "127.255.255." then 
return false 
end

return true
end, 


lookup_ip_in_dbl=function(self, ip, service)
local toks, str
local lookup=""

toks=strutil.TOKENIZER(ip, ".")
str=toks:next()
while str ~= nil
do
	lookup=str.."."..lookup
	str=toks:next()
end

lookup=lookup .. service
str=net.lookupIP(lookup)

return self:interpret_response(service, str)
end,


process_services=function(self, ip)
local i, service

if settings.modsettings["module:dbl:services"] ~= nil
then
	toks=strutil.TOKENIZER(settings.modsettings["module:dbl:services"], ",")
	service=toks:next()
	while service ~= nil
	do
	if self:lookup_ip_in_dbl(ip, service) == true then return true end
	service=toks:next()
	end
end

return false
end,


lookup=function(self)
local i, ip, str

for i,ip in ipairs(lookup_values.dbl_ip_list)
do
	str=ip
	if self:process_services(string.sub(ip, 5)) == true then str=str .. "=yes\n"
	else str=str .. "=no\n"
	end

	print(str)
end

end,



init=function(self, lookups, display_str)
local var_names, i, var

if settings.modsettings["module:dbl:services"] == nil
then
	settings.modsettings["module:dbl:services"]="bl.spamcop.net,zen.spamhaus.org,virus.rbl.jp,cbl.abuseat.org,b.barracudacentral.org"
end

var_names=display:get_vars(display_str)
for i, var in ipairs(var_names)
do

	prefix=string.sub(var, 1, 1)
	if prefix=="$" or prefix=="@" or prefix==">" 
	then
	name=string.sub(var, 3, string.len(var) -1)
	else
	name=var
	end

	if string.sub(name, 1, 4) == "dbl:"
	then
	if lookup_values.dbl_ip_list==nil then lookup_values.dbl_ip_list={} end
	table.insert(lookup_values.dbl_ip_list, name)
	end

end

if lookup_values.dbl_ip_list ~= nil then updater:add_mod(self) end
end
}

table.insert(lookup_modules, mod_dbl)
