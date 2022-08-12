-- functions relating to reading data from sysfs

function SysFSReadFile(path)
local S, str

S=stream.STREAM(path, "r")
if S ~= nil
then
str=S:readln()
str=strutil.stripTrailingWhitespace(str)
S:close()
else
  print("error: can't open: "..path)
end

return(str)
end


