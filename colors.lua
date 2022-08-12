-- functions relating to displayed colors, but these are generic functions not related to a specific display/bartype

function AutoColorValue(value, thresholds)
local color=""

for i,thresh in ipairs(thresholds)
do
  if value > thresh.value then color=thresh.color end
end

return color
end





function TranslateColorName(name)

if name=="black" then return("~n") end
if name=="white" then return("~w") end
if name=="cyan" then return("~c") end
if name=="blue" then return("~b") end
if name=="green" then return("~g") end
if name=="yellow" then return("~y") end
if name=="magenta" then return("~m") end
if name=="orange" then return("~r") end
if name=="red" then return("~r") end

return("")
end


