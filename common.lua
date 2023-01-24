require("stream")
require("time")
require("strutil")
require("filesys")
require("process")
require("terminal")
require("sys")
require("net")
require("dataparser")

SHELL_OKAY=0
SHELL_CLOSED=1
SHELL_CLS=2

version="6.3"
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
