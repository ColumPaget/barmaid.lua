-- functions related to lookups of network values like ip addresses, default gateway, etc


function LookupDefaultRouteIfaceParse(str) 
local toks
local iface, route

toks=strutil.TOKENIZER(str, "\\S")
iface=toks:next()
route=toks:next()

return iface, route
end


function LookupDefaultRouteIface()
local S, str, iface, dest

S=stream.STREAM("/proc/net/route", "r")
if (S)
then
  str=S:readln() -- read 'header' line
  str=S:readln()
  while str ~= nil
  do
    iface,dest=LookupDefaultRouteIfaceParse(str) 
    if dest == "00000000" 
    then 
  S:close()
  return iface 
    end
    str=S:readln()
  end
end

S:close()
return nil
end


function LookupIPv4()
local iface, toks, default_iface

default_iface=LookupDefaultRouteIface()
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
  display_values["ip4interface:default"]=iface
  display_values["ip4address:default"]=sys.ip4address(iface)
  display_values["ip4netmask:default"]=sys.ip4netmask(iface)
  display_values["ip4broadcast:default"]=sys.ip4broadcast(iface)
  end
end

iface=toks:next()
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
