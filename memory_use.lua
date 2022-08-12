--functions related to lookups of memory usage


function LookupMemInfo()
local S, str, toks
local totalmem=0
local availmem=0
local mem_perc

S=stream.STREAM("/proc/meminfo", "r");
if S~= nil
then
  str=S:readln()
  while str ~= nil
  do
  toks=strutil.TOKENIZER(str, ":")
  name=toks:next()
  value=strutil.trim(toks:next())

  toks=strutil.TOKENIZER(value, "\\S")
  value=toks:next()
  if name=="MemTotal" then totalmem=tonumber(value) end
  if name=="MemAvailable" then availmem=tonumber(value) end
  if name=="Cached" then cachedmem=tonumber(value) end
  str=S:readln()
  end
  S:close()
else
  availmem=sys.freemem() + sys.buffermem()
  totalmem=sys.totalmem()
end

display_values["usedmem"]=strutil.toMetric(totalmem-availmem)
display_values["freemem"]=strutil.toMetric(availmem)
display_values["totalmem"]=strutil.toMetric(totalmem)
display_values["cachedmem"]=strutil.toMetric(cachedmem)


mem_perc=availmem * 100 / totalmem
AddDisplayValue("free", mem_perc, "% 3.1f", usage_color_map)

mem_perc=100.0 - (availmem * 100 / totalmem)
AddDisplayValue("mem", mem_perc, "% 3.1f", usage_color_map)

mem_perc=cachedmem * 100 / totalmem
AddDisplayValue("cmem", mem_perc, "% 3.1f", usage_color_map)


--do all the same for swap
availmem=sys.freeswap()
totalmem=sys.totalswap()
display_values["usedswap"]=strutil.toMetric(totalmem-availmem)
display_values["freeswap"]=strutil.toMetric(availmem)
display_values["totalswap"]=strutil.toMetric(totalmem)

if totalmem > 0 
then
  mem_perc=100.0 - (availmem * 100 / totalmem)
else
  mem_perc=0
end

AddDisplayValue("swap", mem_perc, "% 3.1f", usage_color_map)

end

