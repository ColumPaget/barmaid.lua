require("stream")
require("time")
require("strutil")
require("filesys")
require("process")
require("terminal")
require("sys")
require("net")
require("dataparser")
require("hash")

SHELL_OKAY=0
SHELL_CLOSED=1
SHELL_CLS=2

version="7.0"
settings={}
lookup_counter=0
lookup_values={}
display_values={}
lookup_modules={}
display_modules={}
display_translations=nil
poll_streams=stream.POLL_IO()
shell=nil
stdio=nil
datasock=nil

usage_color_map={
        {value=0, color="~g"},
        {value=25, color="~y"},
        {value=75, color="~r"},
        {value=90, color="~R"}
}

thermal_color_map={
        {value=0, color="~c"},
        {value=20, color="~g"},
        {value=40, color="~y"},
        {value=60, color="~r"},
        {value=80, color="~R"}
}


function StringExtract(input, start, end_char)
local i, char
local output=""

i=start

while i < strutil.strlen(input)
do
  char=string.sub(input, i, i)
	if char == end_char then break end
	output=output..char
	i=i+1
end

return i, output
end



