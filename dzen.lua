-- functions related to the DZen2 x11 desktop bar

function DZenFormatOnClick(button, command)
local str=""

str="^ca("..button.."," .. command .. ")" 

return str
end


function DZenStartOnClick(onclick_counter)
local item
local count=0
local str=""

item=onclicks:get(display:curr_num(), onclick_counter)
if item ~= nil
then
      if strutil.strlen(item.left) > 0 then str=str .. DZenFormatOnClick(1, item.left) ; count=count+1 end
      if strutil.strlen(item.middle) > 0 then str=str .. DZenFormatOnClick(2, item.middle) ; count=count+1 end
      if strutil.strlen(item.right) > 0 then str=str .. DZenFormatOnClick(3, item.right) ; count=count+1 end
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
local onclick_counter=0
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
    elseif char==">"
		then
		i,item=StringExtract(str, i + 2, "}")
		outstr=outstr .. "^pa(" .. item .. ")"
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



function DZenLaunch(xpos, ypos)
local str

  str="cmd:dzen2 -x " .. xpos .. " -w " .. settings.win_width 
  if strutil.strlen(settings.ypos) > 0 then str=str .. " -y ".. settings.ypos end
  if strutil.strlen(settings.align) > 0 then str=str .. " -ta " .. settings.align end
  if strutil.strlen(settings.font) > 0 then str=str .. " -fn '" .. settings.font .. "'" end
  if strutil.strlen(settings.foreground) > 0 then str=str .. " -fg '" .. settings.foreground .. "'" end
  if strutil.strlen(settings.background) > 0 then str=str .. " -bg '" .. settings.background .. "'" end
  str=str .. " -e 'button3=print:cycle_display'"
  S=stream.STREAM(str, "rw stderr2null")

print("LAUNCH: "..str)
return S
end
