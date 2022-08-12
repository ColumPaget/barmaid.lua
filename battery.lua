-- functions relating to looking up battery life/usage



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

return bat
end


function GetBatteries()
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


function LookupBatteries()
local bats, i, bat, perc
local bats_str=""
local bats_str_color=""
local color_map={
        {value=0, color="~R"},
        {value=10, color="~r"},
        {value=25, color="~y"},
        {value=75, color="~g"}
}

display_values["bats"]=""
bats=GetBatteries()

for i,bat in ipairs(bats)
do
  name="bat:"..tostring(i-1)
  -- sometimes this is nil, maybe because we've failed to open the file
  if bat.charge ~= nil
  then
    if bat.max ~= nil and bat.max > 0
    then
    perc=math.floor((bat.charge * 100 / bat.max) + 0.5)
    else
    perc=0
  end

  AddDisplayValue(name, perc, "%d", color_map)
  if bat.status == "Charging" then display_values["charging:"..i]="~~" end

  bats_str=bats_str .. name..":"..display_values[name].."%"
  bats_str_color=bats_str_color .. name..":"..display_values[name..":color"].."%"
  if bat.status == "Charging" 
  then
    bats_str=bats_str.."~"
    bats_str_color=bats_str_color.."~"
  else
    bats_str=bats_str.." "
    bats_str_color=bats_str_color.." "
  end
  end
end

display_values["bats"]=bats_str
display_values["bats:color"]=bats_str_color

end

