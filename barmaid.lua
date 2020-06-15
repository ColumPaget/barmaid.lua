require("stream")
require("time")
require("strutil")
require("filesys")
require("process")
require("terminal")
require("sys")

SHELL_OKAY=0
SHELL_CLOSED=1
SHELL_CLS=2

version="2.0"
isc_status=""
counter=0
display_values={}
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


function InternetStormStatus()
local S, str

if counter % 60 == 0
then
S=stream.STREAM("https://isc.sans.edu/infocon.txt", "r")
if S ~= nil
then
	str=S:readln()
	S:close()
end

isc_status=TranslateColorName(str)..str.."~0"
end

return isc_status
end



function DZenTranslateColorStrings(str)
local outstr=""
local i=1
local len, char

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
		elseif char=="0" then outstr=outstr.."^fg()^bg()"
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
elseif settings.output=="lemonbar"
then
	str="cmd:lemonbar -g " .. settings.win_width .. "x"..settings.win_height.."+"..xpos.."+0"
	if strutil.strlen(settings.font) > 0 then str=str .. " -f '" .. settings.font .. "'" end
	if strutil.strlen(settings.foreground) > 0 then str=str .. " -F '" .. settings.foreground .. "'" end
	if strutil.strlen(settings.background) > 0 then str=str .. " -B '" .. settings.background .. "'" end
	S=stream.STREAM(str)
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
local bats, i, bat, perc, color
local str=""
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
	perc=bat.charge * 100 / bat.max

	color=AutoColorValue(perc, color_map)
	str=str..string.format("%s%d~0", color, math.floor(perc + 0.5))
	display_values["bat:"..i]=str
	if bat.status == "Charging" then display_values["charging:"..i]="~~" end

	display_values["bats"]=display_values["bats"].." bat"..i..":"..str.."%"
	if bat.status == "Charging" then display_values["bats"]=display_values["bats"] .. "~~" end
end

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
		display_values["cpu_temp"]=AutoColorValue(val, thermal_color_map)..val.."~0"
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
local Glob, str, path, val

Glob=filesys.GLOB("/sys/class/hwmon/*")
path=Glob:next()
while path ~= nil 
do
	if filesys.exists(path.."/name") == true
	then
	str=SysReadFile(path.."/name")
	if str == "coretemp"
	then
		val=LookupCoreTemp(path)
		display_values["cpu_temp"]=AutoColorValue(val, thermal_color_map)..val.."~0"
	end
	end

	path=Glob:next()
end

end



function LookupTemperatures()
LookupThermal()
LookupHWmon()
end



function LookupPartitions()
local str, perc, color, toks
local S


S=stream.STREAM("/proc/self/mounts", "r")
if S ~= nil
then

	str=S:readln()
	while str ~= nil
	do
		toks=strutil.TOKENIZER(str, "\\S")
		fs_type=toks:next()
		fs_mount=toks:next()

		if fs_type ~= "none" and fs_type ~="cgroups"
		then
			perc=math.floor( (filesys.fs_used(fs_mount) * 100 / filesys.fs_size(fs_mount)) + 0.5)
			color=AutoColorValue(perc, usage_color_map)
		end

		display_values["fs:"..fs_mount]=string.format("%s%1.1f~0", color, perc)

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
display_values["mem"]=AutoColorValue(mem_perc, usage_color_map) ..  string.format("%02.1f", mem_perc) .."~0"


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

display_values["swap"]=AutoColorValue(mem_perc, usage_color_map) ..  string.format("%02.1f", mem_perc) .."~0"


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
	display_values["load"]=string.format("%02.1f", val * cpu_count)
	display_values["load_percent"]=AutoColorValue(val, usage_color_map) .. string.format("%02.1f", val * 100.0) .. "~0"
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




-- this function checks which values have been asked for in a display string, and adds the functions needed to look
-- those items up into the 'lookups' table.
function LookupsFromDisplay(display)
local lookups={}
local names

table.insert(lookups, LookupHostInfo)

for i,str in ipairs( {"$%(time%)", "$%(date%)", "$%(day_name%)", "$%(day%)", "$%(month%)", "$%(month_name%)", "$%(year%)", "$%(hours%)", "$%(minutes%)", "$%(mins%)", "$%(seconds%)", "$%(secs%)"} )
do
	if string.find(display, str) ~= nil
	then
		table.insert(lookups, LookupTimes)
		break
	end
end


if string.find(display, "$%(bat") ~= nil
then
	table.insert(lookups, LookupBatteries)
end


if string.find(display, "$%(fs:") ~= nil
then
	table.insert(lookups, LookupPartitions)
end

if string.find(display, "$%(cpu_temp%)") ~= nil
then
	table.insert(lookups, LookupTemperatures)
end


for i,str in ipairs( {"$%(cpu_count%)", "$%(load"} )
do
if string.find(display, str) ~= nil
then
	table.insert(lookups, CpuUsage)
end
end

for i,str in ipairs( {"$%(load1min", "$%(load5mins%)", "$%(load15mins%)", "$%(load_percent%)"} )
do
if string.find(display, str) ~= nil
then
	table.insert(lookups, LookupLoad)
	break
end
end

if string.find(display, "$%(ip4") ~= nil
then
	table.insert(lookups, LookupIPv4)
end


return lookups
end


function SubstituteDisplayValues(settings)
local toks, str
local output=""

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
		if display_values[str] ~= nil then output=output..display_values[str] end
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
print("-help-colors       - list color switches recognized in format string")
print("-help-values       - list values recognized in format string")
print("-?                 - this help")
print("-help              - this help")
print("--help             - this help")

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
print("Some values, particularly percentages, automatically color themselves") 

os.exit(0)
end


function DisplayHelpValues()
print()
print("Values can be entered into the format string like this: ")
print("  temp:  $(cpu_temp)")
print()
print("The format string should be enclosed in single quotes (') or else the shell will clobber these values.")
print()
print("Available values are:")
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
print("the ip4 values have a special case where the interface suffix is specified as 'default'. In this case the system will go with the first interface it finds that has an ip and isn't the local 'lo' interface")
print("")
print("the default format string is:")
print(settings.display)
os.exit(0)
end


function ParseCommandLine(args)
settings={}

settings.display="~w$(day_name)~0 $(day) $(month_name) ~y$(time)~0 $(bats) fs:$(fs:/)%  mem:$(mem)% load:$(load_percent)% cputemp:$(cpu_temp)c ~y$(ip4address:default)~0"
 
settings.win_width=800
settings.win_height=40
settings.font=""
settings.output="default"
settings.foreground=""
settings.background=""
settings.xpos="center"
settings.ypos=""
settings.steal_lines=0

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
		args[i+1]=""
		if string.sub(settings.foreground, 1, 1) ~= "#" and TranslateColorName(settings.foreground)=="" then settings.foreground="#"..settings.foreground end
	elseif str=="-help-colors" or str=="-help-colours"
	then
		DisplayHelpColors()
	elseif str=="-help-values" or str=="-help-values"
	then
		DisplayHelpValues()
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



settings=ParseCommandLine(arg)
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
		counter=counter+1
		last_time=now
	
		start_ticks=time.millisecs()
		str=SubstituteDisplayValues(settings)
	--	str=str.."ISC:"..InternetStormStatus()
	
		str=TranslateColorStrings(settings, str)
		end_ticks=time.millisecs()
	
		update_display=false
		Out:writeln(str)
		Out:flush()
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
	process.childExited()
end


if settings.ypos=="bottom" then term:clear() end

