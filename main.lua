




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

-- load any modules that extend functionality
LoadModules()

process.configure("mdwe security=untrusted")
display:init()
onclicks:init()
--DataSockAdd(settings.datasock)  
Out=OpenOutput(settings)

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
  
    str=display:substitute_values(settings)
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


-- this function reads data from the next active datastream and processes it
function ProcessStreams()
local S, str

  S=poll_streams:select(100)


--  io.stderr:write("SELECT: "..tostring(S).."\n")
  if S ~= nil
  then
	-- if we are running as a bar within a terminal or xterm then we
	-- need to pass keystrokes through to the shell that's being displayed
	-- along with our bar on that terminal
    if S==stdio 
    then 
      shell:write(stdio:getch(), 1) 
    elseif S==shell
    then
      -- if we are running as a bar within a terminal then we read 
      -- bytes from the shell running in that termina and transfer
      -- them to the screen. There are two special cases SHELL_CLOSED
      -- and SHELL_CLS (clear screen) which must be handled here
      shell_result=TerminalReadFromPty()
      if shell_result==SHELL_CLOSED then return false end
      if shell_result==SHELL_CLS then display_update_required=true end
    -- activity coming from lemonbar or dzen or other 'bar' program
    elseif S==Out
    then
       -- read from the bar program
       str=S:readln()
       if str == nil
       then
	 -- if bar program closes, reopen it	
       	 poll_streams:delete(Out)
         Out:close()
         Out=OpenOutput(settings)
       else
         ProcessBarProgramOutput(str)
       end
    -- our updater process has input
    elseif S==updater:get_stream()
    then
    updater:process_input() 

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

return true
end


function BarmaidMainLoop()
local S

while true
do
  
  now=time.secs()
 
  -- if we get a sigpipe, we ignore it, we don't want to be shut down by this signal
  if process.SIGPIPE ~= nil then process.sigwatch(process.SIGPIPE) end


  -- if we are talking to a shell in a pty  and
  -- if we have a recent enough libUseful-lua to support signals, then
  -- watch for sigwinch (signal for 'window size changed') and sig int (ctrl-c)
  if shell ~= nil
  then
  if process.SIGWINCH ~= nil then process.sigwatch(process.SIGWINCH) end
  if process.SIGINT ~= nil then process.sigwatch(process.SIGINT) end
  end


  if now ~= last_time then display_update_required=true end

  if display_update_required == true then UpdateDisplay() end

  if updater:required(now) == true then updater:launch() end
 
  if ProcessStreams() ~= true then break end

  HandleShellSignals()

  HandleExitedChildProcesses()
end
end





-- MAIN STARTS HERE

ApplicationSetup()


BarmaidMainLoop()


if settings.ypos=="bottom" then term:clear() end

