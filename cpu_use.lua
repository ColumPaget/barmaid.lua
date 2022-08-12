-- functions related to lookups of cpu usage and system load


-- we can get cpu count from /proc/stat
--[[
function LookupCpus()
local S, str
local cpu_count=0

S=stream.STREAM("/proc/cpuinfo", "r")
if S ~= nil
then
  str=S:readln()
  while str ~= nil
  do
    if string.sub(str, 1, 9)=="processor" then cpu_count=cpu_count+1 end
    str=S:readln()
  end
  S:close()
end

display_values["cpu_count"]=cpu_count

end
]]--



function ReadCpuUsageLine(toks)
local total=0
local count=0
local item, val

item=toks:next()
while item ~= nil
do
      val=tonumber(item)
      if val ~= nil
      then
      -- add up user/system/kernel etc, INCLUDING IDLE, to give 'total'
      total=total + val

      -- 3rd item along is 'idle'
      if count==3 then idle=val end

      count=count+1
      end

      item=toks:next()
end

return total-idle, total
end


function CpuUsage()
local key, str
local S, toks, item
local used, total
local cpu_count=0


S=stream.STREAM("/proc/stat", "r")
if S ~= nil
then
  str=S:readln()
  while str ~= nil
  do
    toks=strutil.TOKENIZER(str, " ")
    key=toks:next()
    if key=="cpu"
    then
      key=toks:next()
      used,total=ReadCpuUsageLine(toks)
    elseif string.match(key, "^cpu[0-9]") ~= nil
    then
      cpu_count=cpu_count+1
    end
    str=S:readln()
  end
  S:close()

  display_values["cpu_count"]=cpu_count
  if display_values["cpu_last_used"] ~= nil
  then
  val=(used - tonumber(display_values["cpu_last_used"])) / (total - display_values["cpu_last_total"])
  AddDisplayValue("load", val * cpu_count, "%3.1f", nil)
  AddDisplayValue("load_percent", val * 100.0, "% 3.1f", usage_color_map)
  else
  display_values["load"]="---"
  display_values["load_percent"]="---"
  end

  display_values["cpu_last_used"]=used
  display_values["cpu_last_total"]=total
else
  print("FAIL TO OPEN /proc/stat")
end

end


function CpuFreq()
local Glob, cpuid, path, str
local avg=0 
local cpu_count=0

Glob=filesys.GLOB("/sys/devices/system/cpu/cpu[0-9]*")
path=Glob:next();
while path ~= nil
do
cpuid=filesys.basename(path)
str=SysFSReadFile(path.."/cpufreq/scaling_cur_freq")
display_values["cpu_freq:" .. cpuid]=strutil.toMetric(tonumber(str))
avg=avg + tonumber(str)
cpu_count=cpu_count+1
path=Glob:next();
end

if cpu_count > 0
then
display_values["cpu_freq:avg"]=strutil.toMetric(avg / cpu_count)
end

end


function LookupLoad()
local toks, str, val

str=SysFSReadFile("/proc/loadavg")
toks=strutil.TOKENIZER(str, "\\S")

str=toks:next()
display_values["load1min"]=toks:next()
display_values["load5min"]=toks:next()
display_values["load15min"]=toks:next()

end


