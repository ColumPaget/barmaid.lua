require("stream")
require("time")
require("strutil")
require("filesys")
require("process")
require("terminal")
require("sys")
require("net")
require("dataparser")

SHELL_OKAY=0
SHELL_CLOSED=1
SHELL_CLS=2

version="6.2"
settings={}
lookup_counter=0
lookup_values={}
display_values={}
lookup_modules={}
display_modules={}
display_translations=nil
poll_streams=stream.POLL_IO()
shell=nil
stdio=nil
datasock=nil

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
-- functions relating to displayed colors, but these are generic functions not related to a specific display/bartype

function AutoColorValue(value, thresholds)
local color=""

for i,thresh in ipairs(thresholds)
do
  if value >= thresh.value then color=thresh.color end
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


--functions related to loading images that are used with bars like dzen2 and lemonbar that support this feature

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

return cache_path
end


-- clips out an image path from a '~i{path}' display string entry
function TranslateClipImagePath(str, i)
local val, item

i=i+2
val=string.find(string.sub(str, i), "}")
item=string.sub(str, i, i+val-2)

if string.sub(item, 1, 1) ~= '/'
then
	item=filesys.find(item, settings.icon_path)
end

if filesys.exists(item) == true 
then 
item=ConvertImageToXPM(item) 
else
item=nil
end


i=i+val-1

return i,item
end


-- functions related to the DZen2 x11 desktop bar

function DZenStartOnClick(onclick_counter)
local item
local count=0
local str=""

item=OnClickGet(onclick_counter)
if item ~= nil
then
      if strutil.strlen(item.left) > 0 then str=str.."^ca(1," .. item.left .. ")" ; count=count+1 end
      if strutil.strlen(item.middle) > 0 then str=str.."^ca(2," .. item.middle .. ")" ; count=count+1 end
      if strutil.strlen(item.right) > 0 then str=str.."^ca(3," .. item.right .. ")" ; count=count+1 end
end

return str, count
end

function DZenCloseOnClick(buttons)
local i
local str=""

for i=1,buttons,1
do
      str=str.."^ca()" 
end

return str
end

function DZenTranslateColorStrings(str)
local outstr=""
local i=1
local len, char, val, item
local onclick_counter=1
local buttons=0

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
      if item ~= nil then outstr=outstr.."^i("..item..")" end
    elseif char=="{"
    then
      item,buttons=DZenStartOnClick(onclick_counter)
      outstr=outstr .. item
      onclick_counter=onclick_counter+1
     elseif char=="}"
    then 
      outstr=outstr .. DZenCloseOnClick(buttons)
      buttons=0
    elseif char=="0" then outstr=outstr.."^fg()^bg()"
    else outstr=outstr.."~"..char
    end
  else outstr=outstr..char
  end

  i=i+1
end

return(outstr)
end


-- functions related to the lemonbar x11 desktop bar


function LemonbarStartOnClick(onclick_counter)
local item
local count=0
local str=""

item=OnClickGet(onclick_counter)
if item ~= nil
then
      if strutil.strlen(item.left) > 0 then str=str.."%{A:" .. string.format("click=%d", onclick_counter) .. ":}" ; count=count+1 end
      if strutil.strlen(item.middle) > 0 then str=str.."%{A2:" .. string.format("click=%d", onclick_counter) .. ":}" ; count=count+1 end
      if strutil.strlen(item.right) > 0 then str=str.."%{A3:" .. string.format("click3=%d", onclick_counter) .. ":}" ; count=count+1 end
end

return str, count
end


function LemonbarCloseOnClick(buttons)
local i
local str=""

for i=1,buttons,1
do
      str=str.."%{A}" 
end

return str
end


function LemonbarProcessClick(str)
local val, item

if string.sub(str, 1, 6) == "click="
then
  val=tonumber(string.sub(str, 7))
  item=OnClickGet(val, "left")
  if item ~= nil then process.spawn(item) end
elseif string.sub(str, 1, 7) == "click2="
then
  val=tonumber(string.sub(str, 8))
  item=OnClickGet(val, "middle")
  if item ~= nil then process.spawn(item) end
elseif string.sub(str, 1, 7) == "click3="
then
  val=tonumber(string.sub(str, 8))
  item=OnClickGet(val, "right")
  if item ~= nil then process.spawn(item) end
end

end



function LemonbarTranslateColorStrings(str)
local outstr=""
local i=1
local len, char, item, buttons
local onclick_counter=1

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
    --  io.stderr:write("images not supported in lemonbar. ignoring ".. item .."\n")
    elseif char=="{"
    then
      item,buttons=LemonbarStartOnClick(onclick_counter)
      outstr = outstr .. item
      onclick_counter=onclick_counter+1
    elseif char=="}"
    then 
	LemonbarCloseOnClick(buttons)
	buttons=0
    else outstr=outstr..char
    end
  elseif char=="%" then outstr=outstr.."%%"
  else outstr=outstr..char
  end

  i=i+1
end

return(outstr)
end


-- These functions all relate to bars displayed in the terminal using vt100/ansi escape sequences


-- convert a display string to vt/ansi color codes
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



-- Before this function is called, the user is running a shell on a pty. Then they run barmaid. barmaid then opens a 
-- new shell in a pty, thus 'wrapping' the terminal/shell/pty and interjecting itself between the user and the shell/pty. 
-- Barmaid can now inject text and escape sequences into the stream of characters coming from the shell, allowing it to 
-- decorate the terminal by using escape sequences to set the xterm title, or create a text bar at the bottom of the screen.
function TerminalWrap(steal_lines)
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


--this function reads from the pty/shell if we are in terminal mode and have 
--spawned off a subshell to decorate with a bar
function TerminalReadFromPty()
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

-- functions related to generic bars (like dwm bar) that do not support colors and other features

--basically strips all color formatting for status bars that do not
--support this
function MonochromeTranslateOutput(str)
local i=1
local len, char
local outstr=""

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

return(outstr)
end


-- functions relating to outputting to the title bar of an xterm

-- build escape sequence to set text in xterm title bar
function XtermTitleTranslateOutput(str)
return("\x1b]2;" .. MonochromeTranslateOutput(str) ..  "\x07")
end



--functions related to X11. Mostly figuring out screen width int order to position bar

function X11GetRootGeometry()
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


function X11TranslateXPos(settings)
local pos

root_width,root_high=X11GetRootGeometry()

if settings.xpos=="center"    then pos=(root_width / 2) - (settings.win_width / 2)
elseif settings.xpos=="right" then pos=root_width - settings.win_width
elseif settings.xpos=="left"  then pos=0
else 
  pos=tonumber(settings.xpos) 
  if pos < 0 then pos=root_width - settings.win_width - pos end
end

return math.floor(pos)
end


-- functions related to output. These are generic functions that then call
-- functions in other units that are specific to an output type

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
  elseif settings.output=="dwm"
  then
    return(MonochromeTranslateOutput(input))
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




function OpenOutput(settings)
local width, height, xpos, S
local str=""

xpos=X11TranslateXPos(settings) 
if settings.output=="dzen2"
then
  str="cmd:dzen2 -x " .. xpos .. " -w " .. settings.win_width 
  if strutil.strlen(settings.ypos) > 0 then str=str .. " -y ".. settings.ypos end
  if strutil.strlen(settings.align) > 0 then str=str .. " -ta " .. settings.align end
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
  S=TerminalWrap(settings.steal_lines)
else 
  if settings.ypos=="bottom" --put bar at bottom of screen, wrap terminal
  then
    -- for some reason we have to steal two lines for this to work at all
    S=TerminalWrap(settings.steal_lines)
  else
    S=stream.STREAM("-")
  end
end

return S
end


function ProcessBarProgramOutput(str)
str=strutil.trim(str)
if string.sub(str, 1, 6) == "reload" then KvReloadCounter(string.sub(str, 8)) end
if settings.output=="lemonbar" then LemonbarProcessClick(str) end
end

-- functions relating to reading data from sysfs

function SysFSReadFile(path)
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


-- functions related to key-value messages sent to us from other programs

function KvReloadCounter(name)
local S, str
local count=0


str=process.getenv("HOME").."/.barmaid/"..name..".lst"
S=stream.STREAM(str, "r")
if S ~= nil
then
  str=S:readln()
  while str ~= nil
  do
  count=count+1
  str=S:readln()
  end
  S:close()
end

display_values[name]=count

end


function KvUpdateCounter(name, value)
local val

if strutil.strlen(value)==0
then 
  val=0
elseif display_values[name] ~= nil 
then 
  val=tonumber(display_values[name]) +1
else 
  val=1 
end

display_values[name]=val
end


function KvUpdateListFile(name, value)
local S, path, mode

path=process.getenv("HOME").."/.barmaid/"..name..".lst"
filesys.mkdirPath(path)
if strutil.strlen(value) == 0 then mode="w"
else mode="a" 
end

S=stream.STREAM(path, mode)
if S ~= nil
then
if strutil.strlen(value) > 0 then S:writeln(value.."\n") end
S:close()
end

end


function KvLineRead(S)
local line, str, toks, prefix, name, value

line=S:readln()

if line ~= nil
then
  line=strutil.trim(line)

  if string.len(line) > 0
  then
  toks=strutil.TOKENIZER(line, "=")
  str=toks:next()
  prefix=string.sub(str, 1, 1)
  name=string.sub(str, 2)
  value=toks:remaining()

  if prefix=="@"
  then
    KvUpdateCounter(name, value)
  elseif prefix==">"
  then
    KvUpdateCounter(name, value)
    KvUpdateListFile(name, value)
  else -- if prefix isn't a prefix char, then name is the whole of 'str'
    display_values[str]=toks:remaining()
  end
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


-- functions relating to the unix socket that we can receive key-value messages on

function DataSockAdd(path)
local Serv

Serv=net.SERVER("unix:"..path, "perms=0666")
if Serv ~= nil 
then 
  datasock=Serv
  poll_streams:add(Serv:get_stream())
end

end


-- these functions relate to the translation system that translates an output value to some other
-- display value


function DisplayTranslations()
translations={}

translations.by_name={}
translations.by_pattern={}


translations.lookup=function(self, str)
local item, pattern

item=self.by_name[str]
if item ~= nil then return item end

for pattern,item in pairs (self.by_pattern)
do
  if strutil.pmatch(pattern, str) == true then return item end
end

return nil
end


translations.process=function(self, value_name, ivalue)
local i, item, value, translate, str

value=ivalue

-- first we consider display modules, which are modules that can translate
-- a string into another before it's displayed
for i,item in ipairs(display_modules)
do
  if item.process ~= nil then value=item.process(value_name, value) end
end

-- 'value' is now either a copy of the original passed-in ivalue or
-- the result of a display-module changing it. We now look this value up
-- in our table of translations to see if we want it translated to another string

--first look to see if there's a translation for value_name=value
str=value_name.."="..value
translate=self:lookup(str)
if translate==nil then translate=self:lookup(value) end
if translate ~= nil then value=translate end

return value
end


translations.add=function(self, pattern, value)

if string.find(pattern, "[*+?%[%]]") ~= nil
then
  self.by_pattern[pattern]=value
else
  self.by_name[pattern]=value
end

end

-- parse a translation of a display output. This is a mapping of a string outputted by a value into
-- another string. Both strings can include ~ formatting, so for instance it's possible to translate
-- a string into an image like so:
-- -tr 'yes:~i{/usr/share/images/ok.jpg}'
translations.parse=function(self, def)
local toks, str

toks=strutil.TOKENIZER(def, "|")
str=toks:next()
if str ~= nil 
then 
  self:add(str, toks:remaining())
end

end


return translations
end


function OnClickAdd(value)
local toks, tok
local click={}

toks=strutil.TOKENIZER(value, "|")

click.left=toks:next()
click.middle=toks:next()
click.right=toks:next()

table.insert(settings.onclicks, click)

end

function OnClickGet(index, button)
return settings.onclicks[index]
end

function OnClickGetButton(index, button)
local click

click=settings.onclicks[index]
if click ~= nil
then
	if button == "left" then return click.left 
	elseif button == "middle" then return click.middle
	elseif button == "right" then return click.right
	end
end

return ""
end
-- functions related to configuration, both on the command-line and from config files


-- set intital value of all settings
function SettingsInit()

settings.display="~w$(day_name)~0 $(day) $(month_name) ~y$(time)~0 $(bats:color) fs:$(fs:/:color)%  mem:$(mem:color)% load:$(load_percent:color)% cputemp:$(cpu_temp:color)c ~y$(ip4address:default)~0"

settings.config_files="~/.config/barmaid.lua/barmaid.conf:~/.config/barmaid.conf"
settings.config_files=settings.config_files .. ":" .. "~/.barmaid.conf"
settings.config_files=settings.config_files .. ":/etc/.barmaid.conf"
settings.modules_dir="/usr/local/lib/barmaid/:/usr/lib/barmaid:~/.local/lib/barmaid"
settings.datasock=""
settings.win_width=800
settings.win_height=40
settings.font=""
settings.output="default"
settings.foreground=""
settings.background=""
settings.xpos="center"
settings.ypos=""
settings.align=""
settings.icon_path=".:/usr/share/icons"
--steal lines is lines to take from the terminal when acting as a terminal bar
settings.steal_lines=0
settings.datafeeds={}
settings.onclicks={}
settings.modsettings={}

return settings
end


function GeometryStringNext(toks)
local tok

tok=toks:next()
if tok=="+" then return(tonumber(toks:next()))
elseif tok=="-" then return(0-tonumber(toks:next()))
else return(tonumber(toks:next()))
end

end


function ParseGeometryString(geometry)
local toks, tok

toks=strutil.TOKENIZER(geometry, "+|-", "ms")
settings.x=GeometryStringNext(toks)
settings.y=GeometryStringNext(toks)
settings.width=GeometryStringNext(toks)
settings.length=GeometryStringNext(toks)

end


function LoadConfigFile(path)
local S, str, name, value
local retval=true

if strutil.strlen(path) ==0 then return false end

if string.sub(path, 1, 1) == "~" then path=process.getenv("HOME") .. string.sub(path, 2) end

S=stream.STREAM(path, "r")
if S ~= nil
then
retval=true
str=S:readln()
while str ~= nil
do
  str=strutil.trim(str)

  --if string starts with '#' then it's a comment
  if strutil.strlen(str) > 0 and string.sub(1,1) ~= '#'
  then
  toks=strutil.TOKENIZER(str, " ")
  name=toks:next()
  value=strutil.stripQuotes(toks:remaining())

  if name=="display" or name=="display-string"
  then 
    settings.display=value
  elseif name=="xpos"
  then
    settings.xpos=value
  elseif name=="ypos"
  then
    settings.ypos=value
  elseif name=="width"
  then
    settings.win_width=tonumber(value)
  elseif name=="height"
  then
    settings.win_height=tonumber(value)
  elseif name=="geometry"
  then
    ParseGeometryString(value)
  elseif name=="align"
  then
    settings.align=value
  elseif name=="font" or name=="fn"
  then
    settings.font=value
  elseif name=="foreground" or name=="fg"
  then
    settings.foreground=value
  elseif name=="background" or name=="bg"
  then
    settings.background=value
  elseif name=="translate" or name=="tr"
  then
    display_translations:parse(value)
  elseif name=="output" or name=="outtype"
  then
    settings.output=value
  elseif name=="kvfile"
  then
    KvFileAdd(value)  
  elseif name=="icon_path"
  then
    settings.icon_path=value  
  elseif name=="icon-path"
  then
    settings.icon_path=value  
  elseif name=="iconpath"
  then
    settings.icon_path=value  
  elseif name=="datasock"
  then
    settings.datasock=value
  elseif name=="onclick"
  then
    OnClickAdd(value)
  end
  end
  str=S:readln()

end
S:close()
end

return retval
end



function LoadConfigFiles()
local toks, path

toks=strutil.TOKENIZER(settings.config_files, ":")
path=toks:next()
while path ~= nil
do
  if LoadConfigFile(path) then break end
  path=toks:next()
end

end


function ParseCommandLineConfigFiles(args)

for i,str in ipairs(args)
do
  if str=="-c" 
  then 
    settings.config_files=args[i+1] 
    args[i+1]=""
  end
end

end



function ParseCommandLine(args)

for i,str in ipairs(args)
do
  if str=="-c" then
    --ignore this as we've already parsed it in 'ParseCommandLineConfigFiles'
    args[i+1]=""
  elseif str=="-w" then 
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
  elseif str=="-a" or str=="-align" then
    settings.align=args[i+1]
    args[i+1]=""
  elseif str=="-fg" or str=="-foreground" then
    settings.foreground=args[i+1]
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
  elseif str=="-tr"
  then
    ParseDisplayTranslation(args[i+1])
    args[i+1]=""
  elseif str=="-sock"
  then
    settings.datasock=args[i+1]
    args[i+1]=""
  elseif str=="-onclick"
  then
    OnClickAdd(args[i+1])
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
  elseif str=="-help-translate" or str=="--help-translate"
  then
    DisplayHelpTranslate()
  elseif str=="-help-config" or str=="--help-config"
  then
    DisplayHelpConfig()
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

end

-- functions related to displaying help to the user

function DisplayHelp()
print()
print("barmaid.lua  version: " .. version)
print()
print("usage:  lua barmaid.lua [options] [format string]")
print()
print("options:")
print("-c <path>          - path to config file")
print("-t <type>          - type of output. Possible values are 'dzen', 'lemonbar', 'xterm', 'dwm' and 'term'")
print("-x <pos>           - x-position of window, in pixels or 'left', 'right', 'center'")
print("-y <pos>           - y-position of window, in pixels or 'top', 'bottom'")
print("-w <width>         - width of window in pixels")
print("-h <height>        - height of window in pixels")
print("-align <alignment> - set text alignment, 'left', 'right' or 'center'")
print("-fn <font name>    - font to use")
print("-font <font name>  - font to use")
print("-bg <color>        - background color")
print("-fg <color>        - default font/foreground color")
print("-icon-path <path>  - colon seperated path in which to search for icons")
print("-tr <translation>  - translate a value to a different display value")
print("-kvfile <path>     - path to a file that contains name-value pairs")
print("-sock <path>       - path to a unix stream socket that receives name-value pairs")
print("-onclick <command> - register a command to be used in clickable areas (see -help-onclick)")
print("-help-colors       - list color switches recognized in format string")
print("-help-values       - list values recognized in format string")
print("-help-onclick      - explain clickable area system")
print("-help-images       - explain images display system")
print("-help-sock         - explain datasocket system")
print("-help-translate    - explain the value translate system")
print("-help-config       - explain config files")
print("-?                 - this help")
print("-help              - this help")
print("--help             - this help")
print()
print("example format string:")
print("  $(date) $(time)   mem used: $(mem)%  fs used: $(fs:/)%")
print("this format string must be enclosed in single quotes (') if passed on the command-line (rather than in config file), or the shell will eat it.")
print()
print("Alternatively the form '^(' can be used instead of '$(', allowing double-quotes to be used and shell vars to be passed. e.g.:")
print("  host: $HOST  ^(date) ^(time)    mem used: ^(mem)%  fs used: ^(fs:/)%")
print()
print("use '-help-values' to get a list of values that can be included in the format string, and '-help-colors' for a list of color-codes")
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

print("Some special values are available that automatically color themselves. See '-help-values'.") 
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
print("memuse         percent memory usage calculated from 'availmem' (see discussion below for difference to 'mem')")
print("usedmem        used memory in metric format")
print("freemem        free memory in metric format")
print("availmem       available memory in metric format (see below on difference to freemem)")
print("totalmem       total memory in metric format")
print("cachedmem      cached memory in metric format, this can include ramdisks etc")
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
print("cpu_freq:<cpuid>       cpu frequency for a specific cpu. <cpuid> has the form 'cpu0', 'cpu1' etc")
print("cpu_freq:avg           average cpu frequency across all cpus")
print("mem:color          percent memory usage")
print("memuse:color       percent memory usage using 'availmem' (see discussion below for difference from 'mem')")
print("free:color         percent memory free")
print("avail:color        percent memory available (see discussion below for difference from free)")
print("cmem:color         percent of memory that is cache")
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
print("up:<host>:<port>   connect to service at 'host' and 'port'. display 'up' if connection succeeds, 'down' if not")
print("dns:<host>         lookup 'host' and return its IP address")
print("dnsup:<host>       lookup 'host' and return 'up' if a value is returned 'down' if not")

print("")

print("'freemem and 'availmem', 'free' and 'avail', and 'mem' and 'memuse' differ. ''freemem', free' and 'mem' are calcluated to align with the output of the command-line 'free' command. 'availmem', 'avail' and 'memuse' are calculated from the /proc/meminfo 'MemAvailable' entry. Usually there should be little difference between these, but one cause of a difference is ramdisks. If you have a tmpfs ramdisk on, say /tmp, and its consuming a lot of memory (perhaps because it contains large files) 'freemem' and 'mem' will show you have plenty of memory, even though you don't, as they will not be aware of memory consumed by the ramdisk. 'availmem' and 'memuse' will be a truer reflection of memory available. If you display both these values, and see a large difference between them, then perhaps you need to check your ramdisks!")

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
print("Clickable areas are supported for dzen2 and lemonbar bars. These are defined using ~{ and ~} to mark the start and the end of a clickable area. These areas then match to -onclick options given on the barmaid command line, or 'onclick' entries in the config file. The first '~{' in the display string matches the first -onclick option, and so on. For example:")
print()
print("   lua barmaid.lua '~{ 1st on click~}  ~{ 2nd on click ~}' -onclick xterm -onclick 'links -g www.google.com'")
print()
print("will create two clickable areas, the first of which will launch and xterm when clicked, and the second will launch the links webbrowser.");
print()
print("To achieve the same thing in the config file:")
print()
print("    display ~{ 1st on click~}  ~{ 2nd on click ~} ")
print("    onclick xterm ")
print("    onclick 'links -g www.google.com'")
print()
print("if it's desired to use the second and third mouse buttons to apply multiple click options to an area, then the pipe/bar symbol '|' can be used to add up to three actions:")
print()
print("    display ~{ 1st on click~}  ~{ 2nd on click ~} ")
print("    onclick xterm|rxvt|kitty ")
print("    onclick 'links -g www.google.com'||firefox")
print()
print("In this example left clicking (button 1) on '1st on click' will launch xterm, middle clicking (button 2) will launch rxvt, and right clicking (button 3) will launch kitty.")
print("Similarly left click on '2nd on click' will launch links, and right click will launch firefox.")
os.exit(0)
end



function DisplayHelpTranslate()

print()
print("There are a two ways to translate a datavalue into something else for display. For instance, some datavalues hold the string 'up' or 'down' to indictate the state of something. Translation modules are lua plug-ins used to perform this task and are not discussed here (see barmaid.lua's README.md file for details). The other method for translating such values is the '-tr' command-line option, or the 'translate' config-file option. In both cases this system uses a configuration string of the form:")
print()
print("  <value>|<translation>")
print()
print("So for example, the following:")
print()
print("  up|~g up ~0")
print()
print("Could be used to color the string 'up' in green (for clarity extra spaces are added around 'up' in the translation). This method could also be used to map 'up' to an icon:")
print()
print("  up|~i{/usr/share/icons/okay.jpg}")
print()
print("This would map all values that consist of the word 'up' to the specified icon.")
print()
print("Sometimes there's a need to specify which value is being translated. Multiple different data lookups could return the same value, and you might want to color them differently. This is achieved with:")
print()
print("  <name>=<value>|<translation>")
print()
print("Where 'name' is the name of a value, and 'value' is it's actual displayed result. E.g.")
print()
print("  up:google.com:80=up|~gG~0")
print()
print("Could be used to supply a green 'G' to indicate google is accessible, but not interfere with any other values that return 'up'")
print()
print("EXAMPLE:")
print()
print("  barmaid.lua 'dns:$(dnsup:google.com)  $(up:google.com:80) $(up:freshcode.club:80) $(up:kernel.org:80)' -tr 'dnsup:google.com=up|~gup~0' -tr 'dnsup:google.com=down|~rDOWN~0' -tr 'up:google.com:80=up|~gG~0' -tr 'up:freshcode.club:80=up|~gF~0' -tr 'up:kernel.org:80=up|~gK~0'")
print()
print("This allows mapping the value 'up' for different variables to different output strings (admittedly all of them green in color).")
print()

print()

os.exit(0)
end




function DisplayHelpConfig()
print("By default barmaid looks for default config files in ~/.config/barmaid.lua/barmaid.conf ~/.config/barmaid.conf, ~/.barmaid.conf and /etc/barmaid.conf. The '-c' command-line option allows changing this search path, like so:")
print()
print("  barmaid.lua -c /config/barmaid.conf:~/etc/barmaid.conf:/usr/local/etc/barmaid.conf")
print()
print("The config file contains entries of the form:")
print()
print("<config type> <value>")
print()
print("Possible config types are:")
print()
print("display            string to be displayed in the bar")
print("display-string     string to be displayed in the bar")
print("output             output type, 'dzen2', 'lemonbar', 'dwm', etc")
print("outtype            output type, 'dzen2', 'lemonbar', 'dwm', etc")
print("xpos               x-position, can be 'left', 'right', 'center' or a pixel-position")
print("ypos               y-position, can be 'left', 'right', 'center' or a pixel-position")
print("width              bar width in pixels")
print("height             bar height in pixels")
print("font               name of font to use in the bar")
print("fn                 name of font to use in the bar")
print("foreground         default foreground color")
print("fg                 default foreground color")
print("background         default background color")
print("bg                 default background color")
print("translate          translate a value to another (see --help-translations")
print("tr                 translate a value to another (see --help-translations")
print("kvfile             path to a key-value file")
print("icon-path          colon-separated search path to find icons")
print("icon_path          colon-separated search path to find icons")
print("iconpath           colon-separated search path to find icons")
print("datasock           path to a datasocket to receive key=value messages on")
print("onclick            configure an 'onclick' (see --help-onclick)")

os.exit(0)
end

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


--functions related to lookups of memory usage


function LookupMemInfo()
local S, str, toks
local totalmem=0
local availmem=0
local cachedmem, buffermem
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
  if name=="MemFree" then freemem=tonumber(value) end
  if name=="MemAvailable" then availmem=tonumber(value) end
  if name=="Cached" then cachedmem=tonumber(value) end
  if name=="Buffers" then buffermem=tonumber(value) end
  str=S:readln()
  end
  S:close()

	freemem=freemem + cachedmem + buffermem
else
  availmem=sys.freemem() + sys.buffermem()
  totalmem=sys.totalmem()
end

display_values["usedmem"]=strutil.toMetric(totalmem-(availmem))
display_values["freemem"]=strutil.toMetric(freemem)
display_values["availmem"]=strutil.toMetric(availmem)
display_values["totalmem"]=strutil.toMetric(totalmem)
display_values["cachedmem"]=strutil.toMetric(cachedmem)


mem_perc=freemem * 100 / totalmem
AddDisplayValue("free", mem_perc, "% 3.1f", usage_color_map)

mem_perc=availmem * 100 / totalmem
AddDisplayValue("avail", mem_perc, "% 3.1f", usage_color_map)

mem_perc=100.0 - (freemem * 100 / totalmem)
AddDisplayValue("mem", mem_perc, "% 3.1f", usage_color_map)

mem_perc=100.0 - (availmem * 100 / totalmem)
AddDisplayValue("memuse", mem_perc, "% 3.1f", usage_color_map)

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
-- functions related to lookups of filesystems/partitions 

function LookupPartitionsGetList()
local toks, str
local parts={}

toks=strutil.TOKENIZER(settings.display, "$(|^(|:|)", "ms")
str=toks:next()
while str ~= nil
do
  if str=="$(" or str=="^("
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
 

function LookupPartitionsAnalyzePartition(part_info, requested_partitions)
local fs_dev, fs_mount, fs_type, toks

toks=strutil.TOKENIZER(part_info, "\\S")
fs_dev=toks:next()
fs_mount=toks:next()
fs_type=toks:next()

if fs_dev == "none" and fs_type ~= "tmpfs" then return nil end
if fs_dev == "cgroups" then return nil end

if requested_partitions[fs_mount] ~= nil then return fs_mount end

return nil
end


function LookupPartitions()
local str, perc
local fs_mount
local S, requested_partitions


requested_partitions=LookupPartitionsGetList()

S=stream.STREAM("/proc/self/mounts", "r")
if S ~= nil
then

  str=S:readln()
  while str ~= nil
  do
		fs_mount=LookupPartitionsAnalyzePartition(str, requested_partitions)
    if fs_mount ~= nil
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

-- functions related to lookups of date and time

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




-- these functions relate to loading modules that add features or otherwise change the behavior of barmaid


function LoadModulesFromDir(dir)
local str, glob

  glob=filesys.GLOB(dir.."/*.lua")
  str=glob:next()
  while str ~= nil
  do
    dofile(str)
    str=glob:next()
  end
end

function LoadModules()
local toks, path

toks=strutil.TOKENIZER(settings.modules_dir, ":")
path=toks:next()
while path ~= nil
do
  if string.sub(path, 1, 1) == "~" then path=process.getenv("HOME") .. string.sub(path, 2) end


  if LoadModulesFromDir(path) then break end
  path=toks:next()
end
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



function GetDisplayVars(str)
local vars={}

toks=strutil.TOKENIZER(settings.display, "$(|^(|@(|>(|)", "ms")
str=toks:next()
while str ~= nil
do
  if str=="$(" or str=="@(" or str==">(" or str== "^(" then table.insert(vars, str..toks:next()..")") end
  str=toks:next()
end

return vars
end




-- this function adds lookup functions to the 'lookups' table
-- using the badly named 'name' variable which contains the name 
-- of a lookup as it appeared in the main config string for the
-- display bar
function InitializeLookup(lookups, name)
local check_names={}
local prefix

-- set any counter vars to zero initially, so that when the lookup
-- function is called it's counting from the right value!
prefix=string.sub(name, 1, 1)
name=string.sub(name, 3, string.len(name) -1)

if prefix=="@" 
then
  display_values[name]=0 
elseif prefix==">" 
then 
  display_values[name]=0 
  KvUpdateListFile(name, value)
end



check_names={["time"]=1, ["date"]=1, ["day_name"]=1, ["day"]=1, ["month"]=1, ["month_name"]=1, ["year"]=1, ["hours"]=1, ["minutes"]=1, ["mins"]=1, ["seconds"]=1, ["secs"]=1}


if check_names[name] ~= nil
then
    table.insert(lookups, LookupTimes)
end

if string.sub(name, 1, 4) == "bat:" or string.sub(name, 1, 5) == "bats:"
then
  table.insert(lookups, LookupBatteries)
end


if string.sub(name, 1,3) == "fs:"
then
  table.insert(lookups, LookupPartitions)
end

if string.sub(name, 1, 8) == "cpu_temp"
then
  table.insert(lookups, LookupTemperatures)
end

if name == "cpu_count" or string.sub(name, 1, 4) == "load"
then
  table.insert(lookups, CpuUsage)
end

if string.sub(name, 1, 9) == "cpu_freq:"
then
  table.insert(lookups, CpuFreq)
end


if string.sub(name, 1, 4) == "load"
then
  table.insert(lookups, LookupLoad)
end

if string.sub(name, 1, 3) == "ip4"
then
  table.insert(lookups, LookupIPv4)
end

if string.sub(name, 1, 3) == "up:"
then
  table.insert(lookups, LookupServicesUp)
  if lookup_values.ServicesUp == nil then lookup_values.ServicesUp={} end
  table.insert(lookup_values.ServicesUp, string.sub(name, 4))
end

if string.sub(name, 1, 4) == "dns:" or string.sub(name,1,6)=="dnsup:"
then
  table.insert(lookups, LookupDNS)
  if lookup_values.DNSLookups == nil then lookup_values.DNSLookups={} end
  table.insert(lookup_values.DNSLookups, name)
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
  mod:init(lookups, display)
end

return lookups
end




--this function does the actual building of the output string
--it first calls all the lookups to get up-to-date values, then
--builds an output string using those values and does any
--display translation
function SubstituteDisplayValues(settings)
local toks, str, func, feed
local output=""

-- read up to date values from any key-value files
for i,feed in ipairs(settings.datafeeds)
do
  if feed.type=="kvfile" then KvFileRead(feed) end
end

-- call alll lookup functions to get up to date values
for i,func in ipairs(settings.lookups)
do
  func()
end

-- go through display string extracting any variables and
-- substituting them for up-to-date values
toks=strutil.TOKENIZER(settings.display, "$(|^(|@(|>(|)", "ms")
str=toks:next()
while str ~= nil
do
  if str=="$(" or str=="^(" or str=="@(" or str==">("
  then
    str=toks:next()
    if display_values[str] ~= nil 
    then 
      output=output .. display_translations:process(str, display_values[str])
    end
  elseif strutil.strlen(str) and str ~= ")"
  then
    output=output..str
  end
  str=toks:next()
end

if string.find(output, '%(') ~= nil then io.stderr:write("ERR: ["..output.."]\n") end
return output
end






function HandleShellSignals()
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
end

function HandleExitedChildProcesses()
  -- if any child processes have exited, then collect them here
  if process.collect ~= nil
  then
    process.collect()
  else
    -- old function call, will go away eventually
    process.childExited(-1)
  end
end



function ApplicationSetup()

-- assume our output device, whatever it is, can support unicode UTF8
terminal.utf8(3)

-- load some initial settings defaults
SettingsInit()

-- init display_translations system
display_translations=DisplayTranslations()

-- parse command-line, then load config files (which might have been specified on command-line)
-- then parse command-line again because we want command-line options to override config-files
ParseCommandLineConfigFiles(arg)
LoadConfigFiles()
ParseCommandLine(arg)

-- load any modules that extend functionality
LoadModules()

settings.lookups=LookupsFromDisplay(settings.display)
DataSockAdd(settings.datasock)  
Out=OpenOutput(settings)
poll_streams:add(Out)

if settings.output == "term" 
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

end



function UpdateDisplay()
    last_time=now
  
    str=SubstituteDisplayValues(settings)
    str=TranslateColorStrings(settings, str)
    str=terminal.format(str)
    display_update_required=false

		-- dwm uses the 'name' value of the root window as it's input, so we have to set that
    if settings.output == "dwm"
    then
    os.execute("xsetroot -name '"..str.."'")
		-- for other 'bar' programs we write to standard out
    else
    Out:writeln(str)
    Out:flush()
    end

    lookup_counter=lookup_counter+1
end




-- MAIN STARTS HERE

ApplicationSetup()

while true
do
  
  now=time.secs()
  if now ~= last_time then display_update_required=true end
  if display_update_required == true then UpdateDisplay() end
  
  
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
      shell_result=TerminalReadFromPty()
      if shell_result==SHELL_CLOSED then break end
      if shell_result==SHELL_CLS then display_update_required=true end
    -- activity coming from lemonbar or dzen or other 'bar' program
    elseif S==Out
    then
    ProcessBarProgramOutput(S:readln())
    -- our listening datasocket has recieved a connection, accept a new client who will
    -- send us messages
    elseif S==datasock:get_stream()
    then
      S=datasock:accept()
      poll_streams:add(S)
    -- anything else must be coming from a client program that has connected to our datasock
    elseif KvLineRead(S) == false
    then
      poll_streams:delete(S)
      S:close()                
    end
  end

HandleShellSignals();
HandleExitedChildProcesses()

end


if settings.ypos=="bottom" then term:clear() end

