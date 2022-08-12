-- functions related to the DZen2 x11 desktop bar


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
      if item ~= nil then outstr=outstr.."^i("..item..")" end
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


