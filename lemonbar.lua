-- functions related to the lemonbar x11 desktop bar

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
    --  io.stderr:write("images not supported in lemonbar. ignoring ".. item .."\n")
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


