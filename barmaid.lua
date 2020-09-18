require("stream")
require("time")
require("strutil")
require("filesys")
require("process")
require("terminal")
require("sys")
require("net")

SHELL_OKAY=0
SHELL_CLOSED=1
SHELL_CLS=2

version="4.0"
lookup_counter=0
display_values={}
lookup_modules={}
display_modules={}
poll_streams=stream.POLL_IO()
shell=nil
stdio=nil

usage_color_map={
				{value=0, color="~g"},
				{value=25, color="~y"},
				{value=75, color="~r"},
				{value=90, color="~R"}
}

thermal_color_map={
				{value=0, color="~c"},
				{value=20, color="~g"},
				{value=40, color="~y"},
				{value=60, color="~r"},
				{value=80, color="~R"}
}




function AutoColorValue(value, thresholds)
local color=""

for i,thresh in ipairs(thresholds)
do
	if value > thresh.value then color=thresh.color end
end

return color
end


function AddDisplayValue(name, value, fmtstr, colormap)
local valstr

	if fmtstr ~= nil 
	then 
	valstr=string.format(fmtstr, value) 
	else
	valstr=value
	end

	display_values[name]=valstr
	if colormap ~= nil
	then
		display_values[name..":color"]=AutoColorValue(value, colormap)..valstr.."~0"
	end

end




function TranslateColorName(name)

if name=="black" then return("~n") end
if name=="white" then return("~w") end
if name=="cyan" then return("~c") end
if name=="blue" then return("~b") end
if name=="green" then return("~g") end
if name=="yellow" then return("~y") end
if name=="magenta" then return("~m") end
if name=="orange" then return("~r") end
if name=="red" then return("~r") end

return("")
end


function GetDisplayVars(str)
local vars={}

toks=strutil.TOKENIZER(settings.display, "$(|)", "ms")
str=toks:next()
while str ~= nil
do
	if str=="$(" then table.insert(vars, toks:next()) end
	str=toks:next()
end

return vars
end



function GetRootGeometry()
local S, line, wid, high
local geom=""

S=stream.STREAM("cmd:xwininfo -root")
line=S:readln()
while line ~= nil
do
	line=strutil.stripLeadingWhitespace(line)
	line=strutil.stripTrailingWhitespace(line)
	if string.sub(line, 1, 10) == "-geometry " then geom=string.sub(line, 11) end
	line=S:readln()
end
S:close()

toks=strutil.TOKENIZER(geom, " |+|x", "m")
wid=toks:next()
high=toks:next()

return wid,high
end



function SysReadFile(path)
local S, str

S=stream.STREAM(path, "r")
if S ~= nil
then
str=S:readln()
str=strutil.stripTrailingWhitespace(str)
S:close()
else
	print("error: can't open: "..path)
end

return(str)
end



function TranslateXPos(settings)
local pos

root_width,root_high=GetRootGeometry()

if settings.xpos=="center"    then pos=(root_width / 2) - (settings.win_width / 2)
elseif settings.xpos=="right" then pos=root_width - settings.win_width
elseif settings.xpos=="left"  then pos=0
else 
	pos=tonumber(settings.xpos) 
	if pos < 0 then pos=root_width - settings.win_width - pos end
end

return math.floor(pos)
end


--checks if a .xpm version of an image has been cached in ~/.local/share/cache/icons
--and uses ImageMagick 'convert' utility to create one if not
function ConvertImageToXPM(path)
local extn, str

extn=filesys.extn(path)
if extn==".xpm" then return path end 

str=string.gsub(filesys.basename(path), extn, ".xpm")
cache_path=process.getenv("HOME") .. "/.local/share/cache/icons/" .. str
if filesys.exists(cache_path) then return cache_path end

filesys.mkdirPath(cache_path)
os.execute("convert "..path.." "..cache_path)

print("convert: "..path.." "..cache_path)
return cache_path
end


-- clips out an image path from a '~i{path}' display string entry
function TranslateClipImagePath(str, i)
local val, item

i=i+2
val=string.find(string.sub(str, i), "}")
item=string.sub(str, i, i+val-2)
item=ConvertImageToXPM(item)
i=i+val-1

return i,item
end


function DZenTranslateColorStrings(str)
local outstr=""
local i=1
local len, char, val
local onclick_counter=1, item

len=strutil.strlen(str)
while i <= len
do
	char=string.sub(str, i, i)
	if char=="~" 
	then 
		i=i+1
		char=string.sub(str, i, i)		
		if char=="r" then outstr=outstr.."^fg(red)"
		elseif char=="y" then outstr=outstr.."^fg(yellow)"
		elseif char=="g" then outstr=outstr.."^fg(green)"
		elseif char=="m" then outstr=outstr.."^fg(magenta)"
		elseif char=="b" then outstr=outstr.."^fg(blue)"
		elseif char=="c" then outstr=outstr.."^fg(cyan)"
		elseif char=="w" then outstr=outstr.."^fg(white)"
		elseif char=="R" then outstr=outstr.."^bg(red)"
		elseif char=="Y" then outstr=outstr.."^bg(yellow)"
		elseif char=="G" then outstr=outstr.."^bg(green)"
		elseif char=="M" then outstr=outstr.."^bg(magenta)"
		elseif char=="B" then outstr=outstr.."^bg(blue)"
		elseif char=="C" then outstr=outstr.."^bg(cyan)"
		elseif char=="W" then outstr=outstr.."^bg(white)"
		elseif char=="~" then outstr=outstr.."~"
		elseif char=="i"
		then
			i,item=TranslateClipImagePath(str, i)
			item=ConvertImageToXPM(item)
			outstr=outstr.."^i("..item..")"
		elseif char=="{"
		then
			item=settings.onclicks[onclick_counter]
			if item ~= nil
			then
			outstr=outstr.."^ca(1," .. item .. ")"
			onclick_counter=onclick_counter+1
			end
		elseif char=="}"
		then 
			outstr=outstr.."^ca()" 
		elseif char=="0" then outstr=outstr.."^fg()^bg()"
		else outstr=outstr.."~"..char
		end
	else outstr=outstr..char
	end

	i=i+1
end

return(outstr)
end



function LemonbarTranslateColorStrings(str)
local outstr=""
local i=1
local len, char
local onclick_counter=1, item

outstr="%{c}"
len=strutil.strlen(str)
while i <= len
do
	char=string.sub(str, i, i)
	if char=="~" 
	then 
		i=i+1
		char=string.sub(str, i, i)		
		if char=="r" then outstr=outstr.."%{F#ff0000}"
		elseif char=="y" then outstr=outstr.."%{F#ffff00}"
		elseif char=="g" then outstr=outstr.."%{F#00ff00}"
		elseif char=="m" then outstr=outstr.."%{F#ff00ff}"
		elseif char=="b" then outstr=outstr.."%{F#0000ff}"
		elseif char=="c" then outstr=outstr.."%{F#00ffff}"
		elseif char=="w" then outstr=outstr.."%{F#ffffff}"
		elseif char=="R" then outstr=outstr.."%{B#ff0000}"
		elseif char=="Y" then outstr=outstr.."%{B#ffff00}"
		elseif char=="G" then outstr=outstr.."%{B#00ff00}"
		elseif char=="M" then outstr=outstr.."%{B#ff00ff}"
		elseif char=="B" then outstr=outstr.."%{B#0000ff}"
		elseif char=="C" then outstr=outstr.."%{B#00ffff}"
		elseif char=="W" then outstr=outstr.."%{B#ffffff}"
		elseif char=="~" then outstr=outstr.."~"
		elseif char=="0" then outstr=outstr.."%{F-}%{B-}"
		elseif char=="i"
		then
			i,item=TranslateClipImagePath(str, i)
		--	io.stderr:write("images not supported in lemonbar. ignoring ".. item .."\n")
		elseif char=="{"
		then
			item=settings.onclicks[onclick_counter]
			if item ~= nil
			then
			outstr=outstr.."%{A:" .. string.format("click=%d", onclick_counter) .. ":}"
			onclick_counter=onclick_counter+1
			end
		elseif char=="}"
		then 
			outstr=outstr.."%{A}" 
		else outstr=outstr..char
		end
	elseif char=="%" then outstr=outstr.."%%"
	else outstr=outstr..char
	end

	i=i+1
end

return(outstr)
end



function XtermTitleTranslateOutput(str)
local outstr=""
local i=1
local len, char

outstr="\x1b]2;"
len=strutil.strlen(str)
while i <= len
do
	char=string.sub(str, i, i)
	if char=="~" 
	then 
		i=i+1
		char=string.sub(str, i, i)		
		if char=="~" then outstr=outstr.."~" end

	else outstr=outstr..char
	end

	i=i+1
end
outstr=outstr.."\x07"
return(outstr)
end


function TerminalTranslateOutput(settings, input)
local str

if strutil.strlen(settings.term_background) > 0 then input=settings.term_background .. string.gsub(input, "~0", "~0".. settings.term_background) end
if strutil.strlen(settings.term_foreground) > 0 then input=settings.term_foreground .. string.gsub(input, "~0", "~0".. settings.term_foreground) end

str="\r" .. input .. "~>~0"
if settings.ypos=="bottom" 
then 
	str=string.format("\x1b[s\x1b[%d;0H%s\x1b[u", term:length(), str)
end
return(terminal.format(str))
end


function TranslateColorStrings(settings, input)
local str

	if settings.output=="dzen2"
	then
		return(DZenTranslateColorStrings(input).."\n")
	elseif settings.output=="lemonbar"
	then
		return(LemonbarTranslateColorStrings(input).."\n")
	elseif settings.output=="xterm"
	then
		return(XtermTitleTranslateOutput(input))
	else
		return(TerminalTranslateOutput(settings, input))
	end

	return input
end



function CheckForOutputProgram(program)

path=filesys.find(program, process.getenv("PATH"))
if strutil.strlen(path) > 0 
then 
	settings.output=program
	return true
else
	return false
end

end


function SelectOutput(settings)
local str, path

	if settings.output=="default"
	then
		settings.output="term"
		str=process.getenv("DISPLAY")
		if strutil.strlen(str) > 0
		then
			if CheckForOutputProgram("dzen2") ~= true
			then
				CheckForOutputProgram("lemonbar")
			end
		end
	end

end


-- Before this is function is called, the user is running a shell on a pty. Then they run barmaid. barmaid then opens a 
-- new shell in a pty, thus 'wrapping' the terminal/shell/pty and interjecting itself between the user and the shell/pty. 
-- Barmaid can now inject text and escape sequences into the stream of characters coming from the shell, allowing it to 
-- decorate the terminal by using escape sequences to set the xterm title, or create a text bar at the bottom of the screen.

function WrapTerminal(steal_lines)
-- stdio, shell and term are all global because
-- we access them on events

  stdio=stream.STREAM("-")
	shell=stream.STREAM("cmd:/bin/sh", "pty echo")
	term=terminal.TERM(stdio)
	if (steal_lines > 0)
	then	
		term:scrollingregion(0, term:length() -1)
		term:clear()
	end

	shell:ptysize(term:width(), term:length() - steal_lines)
	shell:timeout(10)
	poll_streams:add(shell)
	poll_streams:add(stdio)
	return stdio
end


function OpenOutput(settings)
local width, height, xpos, S
local str=""

xpos=TranslateXPos(settings) 
if settings.output=="dzen2"
then
	str="cmd:dzen2 -x " .. xpos .. " -w " .. settings.win_width 
	if strutil.strlen(settings.font) > 0 then str=str .. " -fn '" .. settings.font .. "'" end
	if strutil.strlen(settings.foreground) > 0 then str=str .. " -fg '" .. settings.foreground .. "'" end
	if strutil.strlen(settings.background) > 0 then str=str .. " -bg '" .. settings.background .. "'" end
	S=stream.STREAM(str)
	poll_streams:add(S)
elseif settings.output=="lemonbar"
then
	str="cmd:lemonbar -g " .. settings.win_width .. "x"..settings.win_height.."+"..xpos.."+0"
	if strutil.strlen(settings.font) > 0 then str=str .. " -f '" .. settings.font .. "'" end
	if strutil.strlen(settings.foreground) > 0 then str=str .. " -F '" .. settings.foreground .. "'" end
	if strutil.strlen(settings.background) > 0 then str=str .. " -B '" .. settings.background .. "'" end
	S=stream.STREAM(str)
	poll_streams:add(S)
elseif settings.output=="xterm" -- put bar in xterm title by wrapping terminal
then
	S=WrapTerminal(settings.steal_lines)
else 
	if settings.ypos=="bottom" --put bar at bottom of screen, wrap terminal
	then
		-- for some reason we have to steal two lines for this to work at all
		S=WrapTerminal(settings.steal_lines)
	else
		S=stream.STREAM("-")
	end
end

return S
end


function LookupTimes()
	display_values.time=time.format("%H:%M:%S")
	display_values.date=time.format("%Y/%m/%d")
	display_values.day_name=time.format("%a")
	display_values.month_name=time.format("%b")
	display_values.hour=time.format("%H")
	display_values.minutes=time.format("%M")
	display_values.seconds=time.format("%S")
	display_values.year=time.format("%Y")
	display_values.month=time.format("%m")
	display_values.day=time.format("%d")
end


function GetBattery(name, path)
local bat={}

bat.name=name
bat.status=SysReadFile(path.."/status")
bat.charge=tonumber(SysReadFile(path.."/charge_now"))
bat.max=tonumber(SysReadFile(path.."/charge_full"))

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
	if filesys.exists(str.."/charge_full") ==true
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
	name="bat:"..i
	perc=math.floor((bat.charge * 100 / bat.max) + 0.5)
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

display_values["bats"]=bats_str
display_values["bats:color"]=bats_str_color

end


function LookupThermal()
local Glob, str, path, val

Glob=filesys.GLOB("/sys/class/thermal/thermal_zone*")
path=Glob:next()
while path ~= nil 
do
	str=SysReadFile(path.."/type")
	if str == "x86_pkg_temp"
	then
		str=SysReadFile(path.."/temp")
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
	str=SysReadFile(path)
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
	str=SysReadFile(path.."/name")
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


function LookupPartitionsGetList()
local toks, str
local parts={}

toks=strutil.TOKENIZER(settings.display, "$(|:|)", "ms")
str=toks:next()
while str ~= nil
do
	if str=="$("
	then
		str=toks:next()
		if str=="fs"
		then
		str=toks:next() --consume the ':'
		str=toks:next()
		parts[str]="y"
		end
	end
	str=toks:next()
end

return parts
end
	

function LookupPartitions()
local str, perc, color, toks
local S, requested_partitions


requested_partitions=LookupPartitionsGetList()

S=stream.STREAM("/proc/self/mounts", "r")
if S ~= nil
then

	str=S:readln()
	while str ~= nil
	do
		toks=strutil.TOKENIZER(str, "\\S")
		fs_type=toks:next()
		fs_mount=toks:next()

		if fs_type ~= "none" and fs_type ~="cgroups" and requested_partitions[fs_mount] ~= nil
		then
			perc=math.floor( (filesys.fs_used(fs_mount) * 100 / filesys.fs_size(fs_mount)) + 0.5)
			AddDisplayValue("fs:"..fs_mount, perc, nil, usage_color_map)
		end

	str=S:readln()
	end

	S:close()
end


return str
end


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

mem_perc=100.0 - (availmem * 100 / totalmem)
AddDisplayValue("mem", mem_perc, "% 3.1f", usage_color_map)


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
	AddDisplayValue("load", val * cpu_count, nil, nil)
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


function LookupLoad()
local toks, str, val

str=SysReadFile("/proc/loadavg")
toks=strutil.TOKENIZER(str, "\\S")

str=toks:next()
display_values["load1min"]=toks:next()
display_values["load5min"]=toks:next()
display_values["load15min"]=toks:next()

end



function LookupHostInfo()
local val

display_values["hostname"]=sys.hostname()
display_values["kernel"]=sys.release()
display_values["arch"]=sys.arch()
display_values["os"]=sys.type()

val=sys.uptime()
if val / (3600 * 365) > 1
then
	display_values["uptime"]=time.formatsecs("%y years %j days %H:%M:%S", val, "GMT")
elseif val / (3600 * 24) > 1
then
	display_values["uptime"]=time.formatsecs("%j days %H:%M:%S", val, "GMT")
else
	display_values["uptime"]=time.formatsecs("%H:%M:%S", val, "GMT")
end

LookupMemInfo();
end



function LookupIPv4()
local str, toks

toks=strutil.TOKENIZER(sys.interfaces(), " ")
str=toks:next()
while str ~= nil
do

if strutil.strlen(sys.ip4address(str)) > 0
then
	display_values["ip4address:"..str]=sys.ip4address(str)
	display_values["ip4netmask:"..str]=sys.ip4netmask(str)
	display_values["ip4broadcast:"..str]=sys.ip4broadcast(str)

	--eventually we will find the default route and decide the default
	--interface from that, but for now this hack is often good enough
	if str ~= "lo"
	then
	display_values["ip4address:default"]=sys.ip4address(str)
	display_values["ip4netmask:default"]=sys.ip4netmask(str)
	display_values["ip4broadcast:default"]=sys.ip4broadcast(str)
	end
end

str=toks:next()
end

end




function InitializeLookup(lookups, var)
local check_names={}

-- set any counter vars to zero initially
if string.sub(var, 1, 1)=="@" then display_values[var]=0 end

check_names={["time"]=1, ["date"]=1, ["day_name"]=1, ["day"]=1, ["month"]=1, ["month_name"]=1, ["year"]=1, ["hours"]=1, ["minutes"]=1, ["mins"]=1, ["seconds"]=1, ["secs"]=1}


if check_names[var] ~= nil
then
		table.insert(lookups, LookupTimes)
end

if string.sub(var, 1, 4) == "bat:"
then
	table.insert(lookups, LookupBatteries)
end


if string.sub(var, 1,3) == "fs:"
then
	table.insert(lookups, LookupPartitions)
end

if string.sub(var, 1, 8) == "cpu_temp"
then
	table.insert(lookups, LookupTemperatures)
end

if var == "cpu_count" or string.sub(var, 1, 4) == "load"
then
	table.insert(lookups, CpuUsage)
end

if string.sub(var, 1, 4) == "load"
then
	table.insert(lookups, LookupLoad)
end

if string.sub(var, 1, 3) == "ip4"
then
	table.insert(lookups, LookupIPv4)
end
end


-- this function checks which values have been asked for in a display string, and adds the functions needed to look
-- those items up into the 'lookups' table.
function LookupsFromDisplay(display)
local lookups={}
local var_names

-- always lookup basic host details
table.insert(lookups, LookupHostInfo)

var_names=GetDisplayVars(display)

for i, var in ipairs(var_names)
do
InitializeLookup(lookups, var)
end

for i,mod in ipairs(lookup_modules)
do
	mod.init(lookups, display)
end

return lookups
end


function ProcessDisplayModules(value_name, value)
local i, item, str

str=value
for i,item in ipairs(display_modules)
do
	if item.process ~= nil then str=item.process(value_name, str) end
end
return str
end


function KvLineRead(S)
local str, toks, name

str=S:readln()
if str ~= nil
then
	str=strutil.trim(str)
	toks=strutil.TOKENIZER(str, "=")
	name=toks:next()
	if string.sub(name, 1,1)=="@"
	then

		if strutil.strlen(toks:remaining())==0
		then 
			val=0
		elseif display_values[name] ~= nil 
		then 
			val=tonumber(display_values[name]) +1
		else val=1 
		end

		display_values[name]=val
	else
		display_values[toks:next()]=toks:remaining()
	end

	return true
else
	return false
end

end


function KvFileRead(feed)
local S

S=stream.STREAM(feed.path)
if S ~= nil
then
	while KvLineRead(S)
	do
		--nothing
	end
	S:close()
end
end


function KvFileAdd(path)
local S 
local feed={}

feed.type="kvfile"
feed.path=path
feed.read=KvFileRead
table.insert(settings.datafeeds, feed)

end




function DataSockAdd(path)
local Serv

Serv=net.SERVER("unix:"..path)
if Serv ~= nil 
then 
	settings.datasock=Serv
	poll_streams:add(Serv:get_stream())
end

end



function SubstituteDisplayValues(settings)
local toks, str, func, feed
local output=""

for i,feed in ipairs(settings.datafeeds)
do
	if feed.type=="kvfile" then KvFileRead(feed) end
end

for i,func in ipairs(settings.lookups)
do
	func()
end

toks=strutil.TOKENIZER(settings.display, "$(|)", "ms")
str=toks:next()
while str ~= nil
do
	if str=="$("
	then
		str=toks:next()
		if display_values[str] ~= nil 
		then 
			output=output .. ProcessDisplayModules(str, display_values[str])
		end
	elseif strutil.strlen(str) and str ~= ")"
	then
		output=output..str
	end
	str=toks:next()
end

return output
end


function DisplayHelp()
print()
print("barmaid.lua  version: " .. version)
print()
print("usage:  lua barmaid.lua [options] [format string]")
print()
print("options:")
print("-t <type>          - type of output. Possible values are 'dzen', 'lemonbar', 'xterm' and 'term'")
print("-x <pos>           - x-position of window, in pixels or 'left', 'right', 'center'")
print("-y <pos>           - y-position of window, in pixels or 'top', 'bottom'")
print("-w <width>         - width of window in pixels")
print("-h <height>        - height of window in pixels")
print("-fn <font name>    - font to use")
print("-font <font name>  - font to use")
print("-bg <color>        - background color")
print("-fg <color>        - default font/foreground color")
print("-kvfile <path>     - path to a file that contains name-value pairs")
print("-sock <path>       - path to a unix stream socket that receives name-value pairs")
print("-onclick <command> - register a command to be used in clickable areas (see -help-onclick)")
print("-help-colors       - list color switches recognized in format string")
print("-help-values       - list values recognized in format string")
print("-help-onclick      - explain clickable area system")
print("-help-images       - explain images display system")
print("-help-sock         - explain datasocket system")
print("-?                 - this help")
print("-help              - this help")
print("--help             - this help")
print()
os.exit(0)
end



function DisplayHelpColors()
print()
print("Colors within the format string can be set using libUseful `~` notation, where the next character is the color prefix. These are then translated for the target output type. Available colors are:")
print()
print("~w  white")
print("~n  black")
print("~b  blue")
print("~c  cyan")
print("~g  green")
print("~y  yellow")
print("~m  magenta")
print("~r  red")
print("~0  reset to default color")
print()
print("The uppercase version of these sets the background instead of the foreground color.")
print()
print("Example:  ~r this text in red ~0 ~w~BThis text white on a blue background~0")
print()
print("~i is a special case that allows the displaying of images in dzen2. See '-help-images'")
print("~{ and ~} are special cases that define clickable areas. See '-help-onclick'")

print("Some special values are availabel that automatically color themselves. See '-help-values'.") 
print()


os.exit(0)
end


function DisplayHelpValues()
print()
print("Values can be entered into the format string like this: ")
print("  temp:  $(cpu_temp)")
print()
print("The format string should be enclosed in single quotes (') or else the shell will clobber these values.")
print()
print("User-defined values (including counters) are possible, and can be set using the 'datasock' system (see -help-sock)")
print()
print("In addition to plain values, barmaid.lua has a number of 'auto-color' values with ':color' appended to their name, which automatically color themselves depending on the values they have.")
print()
print("Available plain values are:")
print()
print("time           display time as %H:%M:%S")
print("date           display date as %Y/%m/%d")
print("day_name       display 3-letter day name (Sun, Mon, Tues...)")
print("month_name     display 3-letter month name")
print("hour")
print("minutes")
print("seconds")
print("year")
print("month")
print("day")
print("hostname       system hostname")
print("arch           system architecture")
print("os             system os type")
print("kernel         kernel version number")
print("uptime         system uptime in $H:%M:%S")
print("cpu_count      number of cpus")
print("cpu_temp       cpu temperature in celsius. Currently only works on systems that have x86_pkg_temp or coretemp type sensors. For multicore systems displays the highest across all CPUs.")
print("mem            percent memory usage")
print("usedmem        used memory in metric format")
print("freemem        free memory in metric format")
print("totalmem       total memory in metric format")
print("swap           percent swap space usage")
print("usedswap       used swap in metric format")
print("freeswap       free swap in metric format")
print("totalswap      total swap in metric format")
print("bat:           percentage remaining battery. This requires a battery number suffix, so `$(bat:0)` for the first battery")
print("charging:      returns the character '~' (to look like an 'AC' symbol) if battery is charging. Requires a battery number suffix")
print("bats           info for all batteries. If no batteries present, this will be blank.")
print("fs:            filesystem use percent. Requires a filesystem mount suffix, so `$(fs:/home)` for filesystem on /home")
print("ip4address:    ip4address. Requires a network interface suffix, e.g. `$(ip4address:eth0)`")
print("ip4netmask:    ip4address. Requires a network interface suffix, e.g. `$(ip4address:eth0)`")
print("ip4broadcast:  ip4address. Requires a network interface suffix, e.g. `$(ip4address:eth0)`")
print("load_percent   system percentage load (instantaneous cpu usage)")
print("load           system load (instantaneous cpu usage) in 'top' format")
print("load1min       1min  load in 'top' format")
print("load5min       5min  load in 'top' format")
print("load15min      15min load in 'top' format")
print("")
print("Available auto-colored values are:")
print()
print("cpu_temp:color     cpu temperature in celsius. Currently only works on systems that have x86_pkg_temp or coretemp type sensors. For multicore systems displays the highest across all CPUs.")
print("mem:color          percent memory usage")
print("usedmem:color      used memory in metric format")
print("freemem:color      free memory in metric format")
print("totalmem:color     total memory in metric format")
print("swap:color         percent swap space usage")
print("usedswap:color     used swap in metric format")
print("freeswap:color     free swap in metric format")
print("totalswap:color    total swap in metric format")
print("bat:<name>:color   percentage remaining battery. This requires a battery number suffix, so `$(bat:0)` for the first battery")
print("bats:color         info for all batteries. If no batteries present, this will be blank.")
print("fs:<path>:color    filesystem use percent. Requires a filesystem mount suffix, so `$(fs:/home)` for filesystem on /home")
print("load_percent:color system percentage load (instantaneous cpu usage)")
print("load:color         system load (instantaneous cpu usage) in 'top' format")
print("load1min:color     1min  load in 'top' format")
print("load5min:color     5min  load in 'top' format")
print("load15min:color    15min load in 'top' format")
print("")

print("the ip4 values have a special case where the interface suffix is specified as 'default'. In this case the system will go with the first interface it finds that has an ip and isn't the local 'lo' interface")
print("")
print("the default format string is:")
print(settings.display)
print()
os.exit(0)
end


function DisplayHelpDatasocket()
print()
print("barmaid.lua can receive messages on a unix socket, specified with the '-sock' option. Messages sent to this socket can then be used to set variables in barmaid in order for them to be displayed. For example:")
print()
print("   barmaid.lua 'message: $(announcement)' -sock /tmp/barmaid.sock")
print()
print("messages can then be sent to this socket in the form 'announcement=system is shutting down' and the variable 'announcement' will be set and displayed. Messages must be terminated with a 'newline' character.") 
print()
print("A special type of variable with names begining with the '@' symbol can be used as a counter. For example:")
print()
print("   barmaid.lua 'events: $(@events)' -sock /tmp/barmaid.sock")
print()
print("will display a counter that can be incremented by sending '@events=something' to the datasocket. Every time such a message is recieved, the counter will increment. The counter can be reset to zero by setting the variable to an empty string by sending '@events='");
print()
os.exit(0)
end


function DisplayHelpImages()

print()
print("barmaid.lua can use images with the dzen2 bar utility. An entry in the display string of the form:")
print()
print("   ~i{/usr/share/icons/warning.jpg}")
print()
print("will display the image '/usr/share/icons/warning.jpg' in the dzen2 bar. Dzen2 only supports .xpm images by default, so barmaid.lua will use the ImageMagick 'convert' program to convert .png or .jpg files before displaying them.");
print()
os.exit(0)
end


function DisplayHelpOnClick()

print()
print("Clickable areas are supported for dzen2 and lemonbar bars. These are defined using ~{ and ~} to mark the start and the end of a clickable area. These areas then match to -onclick options given on the barmad command line. The first '~{' in the display string matches the first -onclick option, and so on. For example:")
print()
print("   lua barmaid.lua '~{ 1st on click~}  ~{ 2nd on click ~}' -onclick xterm -onclick 'links -g www.google.com'")
print()
print("will create two clickable areas, the first of which will launch and xterm when clicked, and the second will launch the links webbrowser.");
print()

os.exit(0)
end



function ParseCommandLine(args)
settings={}

settings.display="~w$(day_name)~0 $(day) $(month_name) ~y$(time)~0 $(bats:color) fs:$(fs:/:color)%  mem:$(mem:color)% load:$(load_percent:color)% cputemp:$(cpu_temp:color)c ~y$(ip4address:default)~0"
 
settings.modules_dir="/usr/local/lib/barmaid/"
settings.win_width=800
settings.win_height=40
settings.font=""
settings.output="default"
settings.foreground=""
settings.background=""
settings.xpos="center"
settings.ypos=""
settings.steal_lines=0
settings.datafeeds={}
settings.onclicks={}

for i,str in ipairs(args)
do

	if str=="-w" then 
		settings.win_width=args[i+1]
		args[i+1]=""
	elseif str=="-h" then 
		settings.win_height=args[i+1]
		args[i+1]=""
	elseif str=="-t" or str=="-type" then
		settings.output=args[i+1]
		args[i+1]=""
	elseif str=="-fn" or str=="-font" then
		settings.font=args[i+1]
		args[i+1]=""
	elseif str=="-x" then
		settings.xpos=args[i+1]
		args[i+1]=""
	elseif str=="-y" then
		settings.ypos=args[i+1]
		args[i+1]=""
	elseif str=="-bg" or str=="-background" then
		settings.background=args[i+1]
		args[i+1]=""
		if string.sub(settings.background, 1, 1) ~= "#" and TranslateColorName(settings.background)=="" then settings.background="#"..settings.background end
	elseif str=="-fg" or str=="-foreground" then
		settings.foreground=args[i+1]
		if string.sub(settings.foreground, 1, 1) ~= "#" and TranslateColorName(settings.foreground)=="" then settings.foreground="#"..settings.foreground end
	elseif str=="-kvfile"
	then
		KvFileAdd(args[i+1])	
		args[i+1]=""
	elseif str=="-sock"
	then
		DataSockAdd(args[i+1])	
		args[i+1]=""
	elseif str=="-onclick"
	then
		table.insert(settings.onclicks, args[i+1])
		args[i+1]=""
	elseif str=="-help-colors" or str=="--help-colors" or str=="-help-colours"
	then
		DisplayHelpColors()
	elseif str=="-help-images" or str=="--help-images"
	then
		DisplayHelpImages()
	elseif str=="-help-values" or str=="--help-values"
	then
		DisplayHelpValues()
	elseif str=="-help-sock" or str=="--help-sock"
	then
		DisplayHelpDatasocket()
	elseif str=="-help-onclick" or str=="--help-onclick"
	then
		DisplayHelpOnClick()
	elseif str=="-?" or str=="-help" or str=="--help"
	then
		DisplayHelp()
	elseif strutil.strlen(args[i]) > 0
	then
		settings.display=args[i]
	end	
end

if settings.output=="terminal" then settings.output="term" end
if settings.output=="term" then settings.steal_lines=2 end
SelectOutput(settings)

return settings
end


--this function reads from the pty/shell if we are in terminal mode and have 
--spawned off a subshell to decorate with a bar
function ReadFromPty()
local ch, seq_cls_len
local seq_cls=string.char(27) .. "[2J"
local seq_count=1
local retval=SHELL_OKAY

	seq_cls_len=string.len(seq_cls)
	ch=shell:readbyte();
	if ch ==-1 then return SHELL_CLOSED end

	while ch > -1
	do
		stdio:write(string.char(ch), 1) 

		if seq_count >= seq_cls_len 
		then
			retval=SHELL_CLS
		elseif string.sub(seq_cls, 1, 1) == string.char(ch) 
		then
			seq_count=seq_count+1
		end

		ch=shell:readbyte();
	end

	shell:flush()
	return retval
end


function LoadModules()
local str, glob

	glob=filesys.GLOB(settings.modules_dir.."/*.lua")
	str=glob:next()
	while str ~= nil
	do
		dofile(str)
		str=glob:next()
	end
end


function ProcessBarProgramOutput(str)

if settings.output=="lemonbar"
then

if string.sub(str, 1, 6) == "click="
then
	val=tonumber(string.sub(str, 7))
	item=settings.onclicks[val]
	if item ~= nil then process.spawn(item) end
end

end

end



-- MAIN STARTS HERE
-- assume our output device, whatever it is, can support unicode UTF8
terminal.utf8(3)

settings=ParseCommandLine(arg)
LoadModules()

settings.lookups=LookupsFromDisplay(settings.display)
Out=OpenOutput(settings)

if settings.output=="term" 
then
	if strutil.strlen(settings.foreground) > 0
	then
		settings.term_foreground=TranslateColorName(settings.foreground)
	end

	if strutil.strlen(settings.background) > 0
	then
		settings.term_background=string.upper(TranslateColorName(settings.background))	
	end
end


last_time=0
while true
do
	
	now=time.secs()
	if now > last_time then update_display=true end
	
	if update_display == true
	then
		last_time=now
	
		start_ticks=time.millisecs()
		str=SubstituteDisplayValues(settings)
	
		str=TranslateColorStrings(settings, str)
		str=terminal.format(str)
		end_ticks=time.millisecs()
	
		update_display=false
		Out:writeln(str)
		Out:flush()
		lookup_counter=lookup_counter+1
	end
	
	
	-- if we are talking to a shell in a pty  and
	-- if we have a recent enough libUseful-lua to support signals, then
	-- watch for sigwinch (signal for 'window size changed') and sig int (ctrl-c)
	if shell ~= nil
	then
	if process.SIGWINCH ~= nil then process.sigwatch(process.SIGWINCH) end
	if process.SIGINT ~= nil then process.sigwatch(process.SIGINT) end
	end
	
	S=poll_streams:select(100)
	if S ~= nil
	then
		if S==stdio 
		then 
			shell:write(stdio:getch(), 1) 
		elseif S==shell
		then
			shell_result=ReadFromPty()
			if shell_result==SHELL_CLOSED then break end
			if shell_result==SHELL_CLS then update_display=true end
		-- activity coming from lemonbar or dzen or other 'bar' program
		elseif S==Out
		then
		ProcessBarProgramOutput(S:readln())
		-- our listening datasocket has recieved a connection, accept a new client who will
		-- send us messages
		elseif S==settings.datasock:get_stream()
		then
			S=settings.datasock:accept()
			poll_streams:add(S)
		-- anything else must be coming from a client program that has connected to our datasock
		elseif KvLineRead(S) == false
		then
			poll_streams:delete(S)
			S:close()								
		end
	end

	-- if we are talking to a shell in a pty (we are in xterm or terminal mode) then
	-- there are signals that we must propgate to the pty
	if shell ~= nil
	then

	if process.SIGWINCH ~= nil and process.sigcheck(process.SIGWINCH) 
	then
		shell:ptysize(term:width(), term:length() - settings.steal_lines)
  end

	if process.SIGINT ~= nil and process.sigcheck(process.SIGINT) 
	then
		shell:write("\x03",1)
  end

	end

	-- if any child processes have exited, then collect them here
	if process.collect ~= nil
	then
		process.collect()
	else
		-- old function call, will go away eventually
		process.childExited(-1)
	end
end


if settings.ypos=="bottom" then term:clear() end

