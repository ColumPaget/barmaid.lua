--functions related to looking up hardware temperature values


function LookupThermal()
local Glob, str, path, val

Glob=filesys.GLOB("/sys/class/thermal/thermal_zone*")
path=Glob:next()
while path ~= nil 
do
  str=SysFSReadFile(path.."/type")
  if str == "x86_pkg_temp"
  then
    str=SysFSReadFile(path.."/temp")
    val=tonumber(str) / 1000.0
    AddDisplayValue("cpu_temp", val, "% 3.1f", thermal_color_map)
  end
  path=Glob:next()
end

end


function LookupCoreTemp(dir)
local Glob, str, path, val
local temp=0

Glob=filesys.GLOB(dir.. "/temp*input")
path=Glob:next()
while path ~= nil 
do
  str=SysFSReadFile(path)
  val=tonumber(str) / 1000
  if val > temp then temp=val end
  path=Glob:next()
end

return temp
end  


function LookupHWmon()
local Glob, str, path

Glob=filesys.GLOB("/sys/class/hwmon/*")
path=Glob:next()
while path ~= nil 
do
  if filesys.exists(path.."/name") == true
  then
  str=SysFSReadFile(path.."/name")
  if str == "coretemp"
  then
    AddDisplayValue("cpu_temp", LookupCoreTemp(path), nil, thermal_color_map)
  end
  end

  path=Glob:next()
end

end



function LookupTemperatures()
LookupThermal()
LookupHWmon()
end

