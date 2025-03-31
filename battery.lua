--[[

Don't try to make this into an object, as Lookup functions
get put in a list and called as functions in that list

]]--

batteries={

read_battery =function(self, name, path)
local bat={}

bat.name=name
bat.charge=0
bat.max=0

bat.status=SysFSReadFile(path.."/status")
if filesys.exists(path.."/charge_full") ==true 
then
bat.charge=tonumber(SysFSReadFile(path.."/charge_now"))
bat.max=tonumber(SysFSReadFile(path.."/charge_full"))
bat.current=tonumber(SysFSReadFile(path.."/current_now"))

elseif filesys.exists(path.."/energy_full") ==true 
then
bat.charge=tonumber(SysFSReadFile(path.."/energy_now"))
bat.max=tonumber(SysFSReadFile(path.."/energy_full"))
bat.power=tonumber(SysFSReadFile(path.."/power_now"))
end


return bat
end,


read_all=function(self)
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
    bat=self:read_battery(name, str)
    table.insert(bats, bat)
  end
  str=Glob:next()
end

return bats
end,


fmt_life=function(self, hours)
local str=""

int,fract=math.modf(hours)
if int > 0 then str=int .. "h" end

str=str.. math.floor(fract * 60) .."m"

return str
end,


calc_life=function(self, bat)
local fill, draw

if bat.energy ~= nil
then
fill=bat.energy
draw=bat.power
else 
fill=bat.charge
draw=bat.current
end

if fill ~= nil and draw ~= nil
then
  AddDisplayValue(name .. ":life", fill / draw, "%.2f", nill)
end

return fill, draw
end,


process_total_life=function(self, total_fill, total_draw)
local nowcs, val, draw_cs, duration_cs

now_cs=time.centisecs()

-- milliWattHours divided by milliWatts gives Hours
if total_draw > 0 then val=total_fill / total_draw
-- charge / current can be more troublesome
elseif self.prev_fill ==nil 
then
self.prev_fill=total_fill
self.prev_cs=now_cs
elseif self.prev_fill ~= total_fill
then
-- charge is in mAh, calculate draw per centisec
duration_cs=now_cs - self.prev_cs
draw_cs = (self.prev_fill - total_fill) / duration_cs
-- convert to draw per hour
total_draw=draw_cs * 100 * 3600 
if total_draw > 0 then val=total_fill / total_draw end
self.prev_fill=total_fill
self.prev_cs=now_cs
end


if val ~= nil
then
   display_values["bats_life"]=self:fmt_life(val)
   
   if val > 1.0 then prefix="~g"
   elseif val > 0.5 then prefix="~y"
   elseif val > 0.1 then prefix="~r"
   else prefix="~R~w"
   end
   
   display_values["bats_life:color"]=prefix .. self:fmt_life(val) .."~0"
end


end,


process=function(self)
local bats, batnum, i, bat, perc, val, prefix, fill, draw
local total_fill=0
local total_draw=0
local bats_str=""
local bats_str_color=""
local color_map={
        {value=0, color="~R"},
        {value=10, color="~r"},
        {value=25, color="~y"},
        {value=75, color="~g"}
}

display_values["bats"]=""
bats=self:read_all()

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
  bats_str=bats_str .. name..":"..display_values[name].."%"
  bats_str_color=bats_str_color .. name..":"..display_values[name..":color"].."%"

  if bat.status == "Charging" then display_values["charging:" .. batnum]="y"
  else display_values["charging:" .. batnum]="n" end

  fill,draw=self:calc_life(bat)
  if fill ~= nil then total_fill=total_fill + fill end
  if draw ~= nil then total_draw=total_draw + draw end
end

display_values["bats"]=bats_str
display_values["bats:color"]=bats_str_color

self:process_total_life(total_fill, total_draw)
end
}

function LookupBatteries()
batteries:process()
end
