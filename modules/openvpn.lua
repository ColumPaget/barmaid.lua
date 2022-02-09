-- This module connects to the openvpn management interface at a given path
-- and looks up the status of the connection

mod={}

-- module init function, setup module and insert it into module table
mod.init=function(self, lookups, display_str)
local pos, str

pos=string.find(display_str, "$%(openvpn:") 

if pos ~= nil
then
str=string.sub(display_str, pos+10)
pos=string.find(str, ")")
if pos > 0 then str=string.sub(str, 1, pos-1) end

print("mgr:" .. str)
lookup_values.openvpn_mgr=str
table.insert(lookups, self.lookup)
end

end


-- module lookup function, do the actual looking up and insert the result
-- into the 'display_values' table
mod.lookup=function(self)
local S, str, toks, path

if lookup_counter % 60 == 0
then

str="NOT_RUNNING"
path=lookup_values.openvpn_mgr
S=stream.STREAM("unix:"..path, "")
if S ~= nil
then
	str=S:readln() --read banner

	S:writeln("state\r\n")
	str=S:readln()
	S:close()

	if strutil.strlen(str) > 0
	then
	toks=strutil.TOKENIZER(str, ",")
	toks:next()

	str=toks:next()
	end
	
end

display_values["openvpn:"..path]=str
end

end

table.insert(lookup_modules, mod)
