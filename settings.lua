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

if strutil.strlen(path) ==0 then return end

if string.sub(path, 1, 1) == "~" then path=process.getenv("HOME") .. string.sub(path, 2) end

S=stream.STREAM(path, "r")
if S ~= nil
then
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
    table.insert(settings.onclicks, value)
  end
  end
  str=S:readln()

end
S:close()
end

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

