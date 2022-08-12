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


