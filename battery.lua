--[[

Don't try to make this into an object, as Lookup functions
get put in a list and called as functions in that list

]]--


function GetBattery(name, path)
local bat={}

bat.name=name
bat.charge=0
bat.max=0

bat.status=SysFSReadFile(path.."/status")
if filesys.exists(path.."/charge_full") ==true 
then
bat.charge=tonumber(SysFSReadFile(path.."/charge_now"))
bat.max=tonumber(SysFSReadFile(path.."/charge_full"))
elseif filesys.exists(path.."/energy_full") ==true 
then
bat.charge=tonumber(SysFSReadFile(path.."/energy_now"))
bat.max=tonumber(SysFSReadFile(path.."/energy_full"))
end

bat.energy=tonumber(SysFSReadFile(path.."/energy_now"))
bat.power=tonumber(SysFSReadFile(path.."/power_now"))

return bat
end


function GetAllBatteries()
local Glob, str, bat
local bats={}

Glob=filesys.GLOB("/sys/class/power_supply/*")
str=Glob:next()
while str ~= nil 
do
  name=filesys.basename(str)
  if 
  filesys.exists(str.."/charge_full") ==true or
  filesys.exists(str.."/energy_full") ==true
  then
    bat=GetBattery(name, str)
    table.insert(bats, bat)
  end
  str=Glob:next()
end

return bats
end


function BatteryFormatLife(hours)
local str=""

int,fract=math.modf(hours)
if int > 0 then str=int .. "h" end

str=str.. math.floor(fract * 60) .."m"

return str
end


function LookupBatteries()
local bats, batnum, i, bat, perc, val, prefix
local total_energy=0
local total_power=0
local bats_str=""
local bats_str_color=""
local color_map={
        {value=0, color="~R"},
        {value=10, color="~r"},
        {value=25, color="~y"},
        {value=75, color="~g"}
}

display_values["bats"]=""
bats=GetAllBatteries()

for i,bat in ipairs(bats)
do
	batnum=tostring(i-1)
  name="bat:"..batnum
  -- sometimes this is nil, maybe because we've failed to open the file
  if bat.charge ~= nil
  then
    if bat.max ~= nil and bat.max > 0
    then
    perc=math.floor((bat.charge * 100 / bat.max) + 0.5)
    else
    perc=0
		end
  end
  AddDisplayValue(name, perc, "%d", color_map)

  if bat.status == "Charging" then display_values["charging:" .. batnum]="y"
  else display_values["charging:" .. batnum]="n" end

	AddDisplayValue(name .. ":life", bat.energy / bat.power, "%.2f", nill)

  bats_str=bats_str .. name..":"..display_values[name].."%"
  bats_str_color=bats_str_color .. name..":"..display_values[name..":color"].."%"

  total_energy=total_energy + bat.energy
  total_power=total_power + bat.power
end

display_values["bats"]=bats_str
display_values["bats:color"]=bats_str_color

-- milliWattHours divided by milliWatts gives Hours
val=total_energy / total_power
display_values["bats_life"]=BatteryFormatLife(val)

if val > 1.0 then prefix="~g"
elseif val > 0.5 then prefix="~y"
elseif val > 0.1 then prefix="~r"
else prefix="~R~w"
end

display_values["bats_life:color"]=prefix .. BatteryFormatLife(val) .."~0"

end

