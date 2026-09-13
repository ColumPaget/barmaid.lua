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


function LookupWifiLevel()
local S, str, toks, tok, val, percent


wifi_db_color_map={
{value=-999, color="~R"},
{value=-70, color="~r"},
{value=-60, color="~y"},
{value=-50, color="~g"},
{value=-30, color="~e~g"}
}




S=stream.STREAM("/proc/net/wireless", "r")
if S ~= nil
then
str=S:readln()
str=S:readln()
str=S:readln()

str=strutil.trim(str)
toks=strutil.TOKENIZER(str, "\\S")
tok=toks:next() --dev
tok=toks:next() --flags
tok=toks:next() --link
if strutil.strlen(tok) > 0
then

display_values["wifi_level"]=tok

tok=toks:next() --link
display_values["wifi_db"]=tok
display:add_value("wifi_db", tonumber(tok), "%d", wifi_db_color_map)

val=tonumber(tok)
percent=(val + 100) * 2

display:add_value("wifi_percent", percent, "% 3.1f", percent_usage_color_map)


if val >= -30 then display_values["wifi_quality"]="high"
elseif val >= -50 then display_values["wifi_quality"]="good"
elseif val >= -60 then display_values["wifi_quality"]="okay"
elseif val >= -70 then display_values["wifi_quality"]="low"
elseif val >= -80 then display_values["wifi_quality"]="poor"
else display_values["wifi_quality"]="bad"
end

if val >= -30 then display_values["wifi_quality:color"]="~e~ghigh~0"
elseif val >= -50 then display_values["wifi_quality:color"]="~ggood~0"
elseif val >= -60 then display_values["wifi_quality:color"]="~yokay~0"
elseif val >= -70 then display_values["wifi_quality:color"]="~ylow~0"
elseif val >= -80 then display_values["wifi_quality:color"]="~rpoor~0"
else display_values["wifi_quality_color"]="~e~rbad~0"
end
end

--[[
−30 dBm 	100% 	1.000 μW 	Maximum Throughput / Perfect Link 	1 meter from router (direct Line of Sight)
−50 dBm 	100% 	10.00 nW 	Full Speed / Low Latency 	Same room (3–5 meters away)
−60 dBm 	80% 	1.000 nW 	Gaming Tier / 4K Streaming Ready 	Adjacent room through 1 interior drywall
−67 dBm 	66% 	0.199 nW 	Enterprise Roaming Boundary Minimum 	Two rooms away or through wood door
−75 dBm 	50% 	31.6 pW 	Basic Browsing / Occasional Buffering 	Different floor or multiple interior walls
−80 dBm 	40% 	10.0 pW 	Unstable / Packet Retransmissions 	Edge of building or through exterior brick
−90 dBm 	20% 	1.0 pW 	Frequent Disconnections / Packet Loss 	Extreme range limit / Dead zone
]]--

S:close()
end

end
