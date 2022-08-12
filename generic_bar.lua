-- functions related to generic bars (like dwm bar) that do not support colors and other features

--basically strips all color formatting for status bars that do not
--support this
function MonochromeTranslateOutput(str)
local i=1
local len, char
local outstr=""

len=strutil.strlen(str)
while i <= len
do
  char=string.sub(str, i, i)
  if char=="~" 
  then 
    i=i+1
    char=string.sub(str, i, i)    
    if char=="~" then outstr=outstr.."~" end

  else outstr=outstr..char
  end

  i=i+1
end

return(outstr)
end


