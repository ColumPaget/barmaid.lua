-- This module looks up ip addresses in DNS blocklist services. It is activated by an entry of the form:
--
-- $(dbl:8.8.8.8)
--
-- in the display string (in this case the ip to lookup is 8.8.8.8). If this ip is in any blacklist, then the string 'yes' is 
-- returned, otherwise the string 'no' is returned


--service list. You can add extra services here
proc=nil


function DBL_InterpretResponse(service, str)

if str == nil then return false end

if string.sub(str, 1, 12) == "127.255.255." then 
return false 
end

return true
end


function DBL_Lookup(ip, service)
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

return DBL_InterpretResponse(service, str)
end


function DBL_ProcessServices(ip)
local i, service

if settings.modsettings["module:dbl:services"] ~= nil
then
	toks=strutil.TOKENIZER(settings.modsettings["module:dbl:services"], ",")
	service=toks:next()
	while service ~= nil
	do
	if DBL_Lookup(ip, service) == true then return true end
	service=toks:next()
	end
end

return false
end


function DBL_ProcessLookups()
local i, ip

for i,ip in ipairs(lookup_values.dbl_ip_list)
do
	if DBL_ProcessServices(string.sub(ip, 5)) == true 
	then 
		io.stdout:write(ip.."=yes\n")
		io.stdout:flush()
	else
		io.stdout:write(ip.."=no\n")
		io.stdout:flush()
	end
end

end


function DBL_Process()


if lookup_counter % 360 == 0
then
	proc=process.PROCESS("")
	if proc ==nil
	then
		DBL_ProcessLookups()
		os.exit()
	else
		poll_streams:add(proc:get_stream())
	end
end
end


function DBL_Init(self, lookups, display_str)
local var_names, i, var

if settings.modsettings["module:dbl:services"] == nil
then
	settings.modsettings["module:dbl:services"]="bl.spamcop.net,sbl.spamhaus.org,virus.rbl.jp,cbl.abuseat.org,dyna.spamrats.com,b.barracudacentral.org"
end

var_names=GetDisplayVars(display_str)
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

if lookup_values.dbl_ip_list ~= nil then table.insert(lookups, self.lookup) end
end


mod={}
mod.lookup=DBL_Process
mod.init=DBL_Init
table.insert(lookup_modules, mod)
