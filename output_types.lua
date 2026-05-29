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
local xpos, S
local str=""


xpos=X11TranslateXPos(settings) 
if settings.output=="dzen2" then S=DZenLaunch(xpos, settings.ypos)
elseif settings.output=="lemonbar" then S=LemonbarLaunch(xpos, settings.ypos)
elseif settings.output=="xterm" then S=TerminalWrap(settings.steal_lines)
else 
  if settings.ypos=="bottom" --put bar at bottom of screen, wrap terminal
  then
    -- for some reason we have to steal two lines for this to work at all
    S=TerminalWrap(settings.steal_lines)
  else
    S=stream.STREAM("-")
  end
end

if S ~= nil then poll_streams:add(S) end


return S
end



function ProcessBarProgramOutput(str)
  str=strutil.trim(str)
  if string.sub(str, 1, 6) == "reload" then KvReloadCounter(string.sub(str, 8)) end
  if string.sub(str, 1, 13) == "cycle_display" then display:cycle(); lookup_counter=0; display:alerts_clear() end
  if settings.output=="lemonbar" then LemonbarProcessClick(str) end
end
