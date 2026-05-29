-- functions related to lookups of network values like ip addresses, default gateway, etc

ip4network={

hextoip=function(self, hex)
local str, ip

str=string.sub(hex, 7, 8)
ip=tostring(tonumber( str, 16)) .. "."

str=string.sub(hex, 5, 6)
ip=ip .. tostring(tonumber( str, 16)) .. "."

str=string.sub(hex, 3, 4)
ip=ip .. tostring(tonumber( str, 16)) .. "."

str=string.sub(hex, 1, 2)
ip=ip .. tostring(tonumber( str, 16))

return ip
end,


route_parse=function(self, str) 
local toks
local iface, route, gateway

toks=strutil.TOKENIZER(str, "\\S")
iface=toks:next()
route=toks:next()
gateway=self:hextoip(toks:next())

return iface, route, gateway
end,


default_route=function(self)
local S, str, iface, dest

S=stream.STREAM("/proc/net/route", "r")
if (S)
then
  str=S:readln() -- read 'header' line
  str=S:readln()
  while str ~= nil
  do
    iface,dest,gateway=self:route_parse(str) 
    if dest == "00000000" 
    then 
      S:close()
      return iface,gateway 
    end
    str=S:readln()
  end
end

S:close()
return nil
end,



lookup_interfaces=function(self, default_iface)
local toks, iface

toks=strutil.TOKENIZER(sys.interfaces(), " ")
iface=toks:next()
while iface ~= nil
do

if strutil.strlen(sys.ip4address(iface)) > 0
then
  display_values["ip4address:"..iface]=sys.ip4address(iface)
  display_values["ip4netmask:"..iface]=sys.ip4netmask(iface)
  display_values["ip4broadcast:"..iface]=sys.ip4broadcast(iface)

  if iface == default_iface
  then
  display_values["ip4address:default"]=sys.ip4address(iface)
  display_values["ip4netmask:default"]=sys.ip4netmask(iface)
  display_values["ip4broadcast:default"]=sys.ip4broadcast(iface)
  end
end

iface=toks:next()
end

end

}



function LookupIPv4(fmt_str)
local iface, toks, str, default_iface, default_gateway
local get_external_ip=false
local get_ip4=false

toks=strutil.TOKENIZER(fmt_str, "$(|^(|:|)", "ms")
str=toks:next()
while str ~= nil
do
  if str == "ip4external" then get_external_ip=true
  elseif string.sub(str, 1, 3) == "ip4" then get_ip4=true
  end
str=toks:next()
end

if get_external_ip == true 
then 
--if lookup_counter % 30 == 0 then display_values["ip4external"]=net.externalIP() end
end

if get_ip4 == true
then
default_iface,default_gateway=ip4network:default_route()

display_values["ip4interface:default"]=default_iface
display_values["ip4gateway:default"]=default_gateway
display_values["ip4gateway"]=default_gateway

ip4network:lookup_interfaces(default_iface)
end

end


function LookupServicesUp()
local i, url, toks, S

if lookup_counter % 30 == 0 and lookup_values.ServicesUp ~= nil
then
  for i,url in ipairs(lookup_values.ServicesUp)
  do
    S=stream.STREAM("tcp:" .. url, "r timeout=20")
    if S ~= nil 
    then
    display_values["up:"..url]="up"
    S:close()
    else
    display_values["up:"..url]="down"
    end
  end
end

end


function LookupDNS()
local i, lookup, host, str

if lookup_counter % 30 ==0 and lookup_values.DNSLookups ~= nil
then
  for i,lookup in ipairs(lookup_values.DNSLookups)
  do
    if string.sub(lookup, 1, 6)=="dnsup:"
    then 
      host=string.sub(lookup, 7) 
    elseif string.sub(lookup, 1, 4)=="dns:"
    then 
      host=string.sub(lookup, 5) 
    else
      host=lookup
    end

    str=net.lookupIP(host)
    if str == nil then str="" end

    if string.sub(lookup, 1, 6)=="dnsup:"
    then

      if string.len(str) > 0
      then
      display_values[lookup]="up"
      else
      display_values[lookup]="down"
      end
    else
      display_values["dns:"..host]=str
    end
  end
end

end
