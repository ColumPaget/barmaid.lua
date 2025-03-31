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
  if char=="^"
  then
  outstr=outstr.."^^"
  elseif char=="~" 
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


