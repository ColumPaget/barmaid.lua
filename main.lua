



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


if check_names[name] ~= nil or string.sub(name, 1, 6) == "tztime" or string.sub(name, 1, 6) == "tzdate"
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

