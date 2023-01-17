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


