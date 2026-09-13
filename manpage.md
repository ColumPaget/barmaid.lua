title: barmaid.lua
mansection: 1
date: 13 sep 2026


SYNOPSIS
========

barmaid.lua is a status-bar generation program with unicode and modules support. It is written in lua using libUseful-lua. It can generate output suitable for dzen2, lemonbar, xterm title-bars, dwm and the terminal. It can display info on date, time, system load, memory usage, partition usage, cpu usage, ip4 address/netmask/broadcast, hostname, kernel, architecture, ostype, uptime, cpu count, battery level, wifi signal strength, cpu temperature and many other things. No external programs are run to generate this data, so barmaid's resource usage should be low. Unfortuantely, as barmaid pulls a lot of data from /proc and /sys, it's a mostly linux-only program. Barmaid is extensible via it's modules system.


USAGE
======

```
lua barmaid.lua [options] [display string]
```

The `display string` is the string to display. Values in it with the format `$(name)` or `^(name)` will be substituted by the program with the appropriate 'live' values. (see more in 'DISPLAY STRING' below)


OPTIONS
=======

-c <path>         
: path to config file
-t <type>         
: type of output. Possible values are 'dzen2', 'dzen', 'lemonbar', 'xterm', 'dwm', 'xterm', 'terminal' and 'term'
-type <type>         
: type of output. Possible values are 'dzen2', 'dzen', 'lemonbar', 'xterm', 'dwm', 'xterm', 'terminal' and 'term'
-x <pos>          
: x-position of window, in pixels or 'left', 'right', 'center'
-y <pos>          
: y-position of window, in pixels or 'top', 'bottom'
-w <width>        
: width of window in pixels
-h <height>       
: height of window in pixels
-C <seconds>      
: 'cycle time' to switch between multiple display strings
-a <alignment>
: set text alignment, 'left', 'right' or 'center'
-align <alignment>
: set text alignment, 'left', 'right' or 'center'
-fn <font name>   
: font to use
-font <font name> 
: font to use
-bg <color>       
: background color either as a name ('red', 'blue') or as an rrggbb hexadecimal 
-fg <color>       
: default font/foreground color either as a name ('red', 'blue') or as an rrggbb hexadecimal 
-icon-path <path> 
: colon seperated path in which to search for icons
-tr <translation> 
: translate a value to a different display value
-kvfile <path>    
: path to a file that contains name-value pairs
-sock <path>      
: path to a unix stream socket that receives name-value pairs from other programs
-onclick <command>
: register a command to be used in clickable areas (see -help-onclick)
-help-colors      
: list color switches recognized in display string
-help-values      
: list values recognized in display string
-help-onclick     
: explain clickable area system
-help-images      
: explain images display system
-help-sock        
: explain datasocket system
-help-translate   
: explain the value translate system
-help-config      
: explain config files
-?                
: top-level help
-help             
: top-level help
--help            
: top-level help



DISPLAY STRING
==============

The 'display string' is either passed on the command-line, or set using the 'display' or 'display-string' options in the config file. It specifies the string to be displayed in the bar. The 'display string'  can contain variables that are substituted with values gathered from the system, and formatting strings that effect colors, positioning and clickable areas. Variables have the form `$(name)` and formatting strings start with `~` (tilde).

The variable values come in two types, plain, and auto-colored. Auto-colored values change color depending on the level of the value.

And example display string might look like:


```
	$(time) host: $(hostname) rootfs: $(fs:/) today: $(date)
```

As the '$' symbol means something to the shell, the display string will have to be supplied within single quotes if passed on the command line. Alternatively the format '^(' can be used instead of '$(', like so:

```
	^(time) ^(hostname) ^(fs:/) ^(date)
```


Colors and other formatting within the display string can be set using libUseful `~` notation, where the next character is the color prefix. Available colors are:


~w
: white foreground
~n
: black foreground
~b
: blue foreground
~c
: cyan foreground
~g
: green foreground
~y
: yellow foreground
~m
: magenta foreground
~r
: red foreground
~W
: white background
~N
: black background
~B
: blue background
~C
: cyan background
~G
: green background
~Y
: yellow background
~M
: magenta background
~R
: red background
~>{pixels}
:position following text 'pixels' into the bar (currently only with dzen2 bars)
~i{path}
:  display image file at path (default xpm, but can display jpeg and png images provided imagemagik 'convert' is installed)
~{click~}
: define a clickable area
~0
: reset to default color
~Uxxxx
:  unicode code point
~:name:
: unicode glyph name



So, for example:

```
	~bdisk:~0 $(fs:/)  ~bmem:~0 $(mem)
```

Will display the words 'disk:' and 'mem:' in blue, in front of the values for root-partition usage and memory usage, which will be in the default color.

```
	~R~w$(hour):$(minutes)~0 $(date)
```

Will display the time (hours and minutes) in white on a red background, and the date with the default colors.

Dzen2 supports images, and these can be set with the notation `~i{/usr/share/icons/world.jpg}`. Dzen2 only supports .xpm images, so barmaid.lua will use the ImageMagick 'convert' utility to convert .png or .jpg 

Some values have alternative versions that are suffixed with ':color'. These values are automatically colored according to their numeric values. Values can also be modified for display using the 'reformat module' method discussed in the 'MODULES' section below.



Available value names that can be included in the display string are:


time
: display time as %H:%M:%S
date
: display date as %Y/%m/%d
day_name
: display 3-letter day name (Sun, Mon, Tues...)
month_name
: display 3-letter month name
hour
: display 2-digit hour
minutes
: display 2-digit minutes
seconds
: display 2-digit seconds
year
: display 4-digit year
month
: display 2-digit month
day
: display 2-digit day
tztime: <zone>
: lookup curr time in timezone. e.g. '$(tztime:America/Chicago)'
tzdate: <zone>
: lookup curr date in timezone. e.g. '$(tzdate:CET)'
hostname
: system hostname
arch
: system architecture
os
: system os type
kernel
: kernel version number
uptime
: system uptime in $H:%M:%S
cpu_count
: number of cpus
cpu_temp
: cpu temperature in celsius. Currently only works on systems that have x86_pkg_temp or coretemp type sensors. For multicore systems displays the highest across all CPUs.
cpu_temp: color
: automatically colored cpu usage (green/yellow/red)
cpu_freq: <cpuid>
: frequency of cpu, where <cpuid> has the form 'cpu0', 'cpu1' etc
cpu_freq: avg
: average cpu frequency across all cpus
total_threads
: total number of cpu threads on the system")
runnable_threads
: number of threads needing cpu-time right now")
mem
: percent memory usage
memuse
: percent memory usage using 'availmem' (see discussion below for difference from 'mem')
free
: percent memory free
avail
: percent memory free (see discussion below for difference from free)
mem: color
: automatically colored memory usage (green/yellow/red)
memuse: color
: percent memory usage using 'availmem' (see discussion below for difference from 'mem')
free: color
: automatically colored percent memory free
avail: color
: percent memory available (see discussion below for difference from free)
usedmem
: used memory in metric format 
freemem
: free memory in metric format
availmem
: free memory in metric format (see discussion below for difference from freemem)
totalmem
: total memory in metric format
cachedmem
: cached memory in metric format, this can include ramdisks etc
cmem
: percent of memory that is cache
cmem: color
: percent of memory that is cache
swap
: percent swap space usage
swap: color
: automatically colored swap usage (green/yellow/red)
usedswap
: used swap in metric format
freeswap
: free swap in metric format
totalswap
: total swap in metric format
bat: <num>
: percentage remaining battery. This requires a battery number suffix, so `$(bat:1)` for the first battery
bat: <num>:color
: automatically colored remainint battery percent (green/yellow/red) requires a battery suffix example: $(bat:1:color)
charging: <num>
: returns the character 'y' if battery is charging, 'n' otherwise. Requires a battery number suffix
bats
: info for all batteries. If no batteries present, this will be blank.
bats: color
: autocolored info for all batteries. If no batteries present, this will be blank.
bats_life
: remaining life of all batteries at current power draw.
bats_life: color
: remaining life of all batteries at current power draw (greem > 1hr, yellow > 0.5 hr, red below 3min)
fs: <mount>
: filesystem use percent. Requires a filesystem mount suffix, so `$(fs:/home)` for filesystem on /home
fs: <mount>:color
: filesystem use percent. Requires a filesystem mount suffix, so `$(fs:/home)` for filesystem on /home
load
: system load (instantaneous cpu usage) in 'top' format
load_percent
: system percentage load/cpu usage
load_percent: color
: autocolored system percentage load/cpu usage
load: color
: instantaneous load/cpu usage in 'top' format
load1min
: 1min load in 'top' format
load5min
: 5min load in 'top' format
load15min
: 15min load in 'top' format
load1min: color
: 1min  load in 'top' format, autocolored.
load5min: color
: 5min  load in 'top' format, autocolored.
load15min: color
: 15min load in 'top' format, autocolored.
ip4interface: <iface>
: requires an interface suffix. Currently only 'default' is supported, which returns the name of interface that has the ip4 default route
ip4address: <iface>
: ip4address. Requires a network interface suffix, e.g. `$(ip4address:eth0)` or `$(ip4address:default)` for ip address on default-route interface
ip4netmask: <iface>
: ip4netmask. Requires a network interface suffix, e.g. `$(ip4netmask:eth0)` or `$(ip4netmask:default)` for ip netmask on default-route interface
ip4broadcast: <iface>
: ip4broadcast. Requires a network interface suffix, e.g. `$(ip4broadcast:eth0)`
ip4gateway
: default gateway for ipv4
up: <host>:<port>
: connect to service at 'host' and 'port'. display 'up' if connection succeeds, 'down' if not
dns: <host>
: lookup 'host' and return its IP address              
dnsup: <host>
: lookup 'host' and return 'up' if a value is returned 'down' if not
wifi_level
: current wifi strength expressed in dB
wifi_db
: current wifi strength expressed in dB
wifi_percent
: current wifi strength expressed as percentage (can go over 100 due to conversion issues from dB)
wifi_quality
: current wifi strength expressed as 'high', 'good', 'okay', 'low', 'poor' and 'bad'
wifi_db: color
: autocolored wifi strength in dB
wifi_percent: color
: autocolored wifi strength in percent
wifi_quality: color
: autocolored wifi strength expressed as 'high', 'good', 'okay', 'low', 'poor' and 'bad'
flagfile: 
: suffix is path to flagfile. value is 'y' if flagfile exists 'n' otherwise
flagfile_when: 
: suffix is path to flagfile. value is mtime of flagfile as  %H:%M:%S when under a day, and %Y-%m-%d when over a day
flagfile_mtime: 
: suffix is path to flagfile. value is mtime of flagfile in %Y-%m-%d %H:%M:%S
flagfile_age: 
: suffix is path to flagfile. value is time since flagfile created/modified in auto-formatting 'duration' format



Please note, any value that has ':' at the end, takes an argument, like `bat:1` or `ip4address:eth0`.

'freemem' and 'availmem', 'free' and 'avail', and 'mem' and 'memuse' differ. 'freemem', 'free' and 'mem' are calcluated to align with the output of the command-line 'free' command. 'availmem', 'avail' and 'memuse' are calculated from the /proc/meminfo 'MemAvailable' entry. Usually there should be little difference between these, but one cause of a difference is ramdisks. If you have a tmpfs ramdisk on, say /tmp, and its consuming a lot of memory (perhaps because it contains large files) 'freemem' and 'mem' will show you have plenty of memory, even though you don't, as they will not be aware of memory consumed by the ramdisk. 'availmem' and 'memuse' will be a truer reflection of memory available. If you display both these values, and see a large difference between them, then perhaps you need to check your ramdisks!

The 'ip4' values have a special case where the interface is specified as 'default' e.g. 'ip4address:default'. In this case details are returned for the first interface that isn't the local interface and has an ip address. 







TERMINAL BOTTOM BAR
===================

If barmaid is run in a terminal with the `-y` argument set to `bottom`, like so:

```
	lua barmaid.lua -t term -y bottom -bg blue
```

Then a bar will be displayed at the bottom of the terminal, with normal terminal output being limited to the lines above it. This is an experimental feature. It's been seen to work in xterm and qterminal, though 'vi' in xterm seems to have some cosmetic issues.




UNICODE
=======

Barmaid supports unicode UTF8 output. Unicode symbols can be included by either:

1) Unicode code-point value. so, for example "~U266B" displays a musical note symbol.
2) Unicode glyph name. This requires a version of libUseful more recent than 4.38 and an '/etc/unicode-names.conf' file. This allows specifying unicode symbols via the notation: "~:music:"




VALUE TRANSLATION
=================

There are a two ways to translate a datavalue into something else for display. For instance, some datavalues hold the string 'up' or 'down' to indictate the state of something. Reformat modules are lua plug-ins used to perform this task and are discussed in the 'MODULES' section below. The other method for translating such values is the '-tr' command-line option, or the 'translate' config-file option. In both cases this system uses a configuration string of the form:

```
  <value>|<translation>
```

So for example, the following:

```
  up|~g up ~0
```

Could be used to color the string 'up' in green (for clarity extra spaces are added around 'up' in the translation). This method could also be used to map 'up' to an icon:

```
  up|~i{/usr/share/icons/okay.jpg}
```

This would map all values that consist of the word 'up' to the specified icon.

Sometimes there's a need to specify which value is being translated. Multiple different data lookups could return the same value, and you might want to color them differently. This is achieved with:

```
  <name>=<value>|<translation>
```

Where 'name' is the name of a value, and 'value' is it's actual displayed result. E.g.

```
  up:google.com:80=up|~gG~0
```

Could be used to supply a green 'G' to indicate google is accessible, but not interfere with any other values that return 'up'.

The 'key' of the translation (i.e. 'name=value') can contain shell/fnmatch-style wildcards. The symbols `*`, `+`, `?`, `[` and `]` will be honored with their shell/fnmatch meanings. `\` can be used to quote these characters.

EXAMPLE:

```
  barmaid.lua 'dns:$(dnsup:google.com)  $(up:google.com:80) $(up:freshcode.club:80) $(up:kernel.org:80)' -tr 'dnsup:google.com=up|~gup~0' -tr 'dnsup:google.com=down|~rDOWN~0' -tr 'up:google.com:80=up|~gG~0' -tr 'up:freshcode.club:80=up|~gF~0' -tr 'up:kernel.org:80=up|~gK~0'
```

This allows mapping the value 'up' for different variables to different output strings (admittedly all of them green in color).



KEY-VALUE DATA
==============

There are two ways that key-value data can be loaded into barmaid and added to the list of values that can be displayed. One method is via 'key value files'. For this method the path to a file is supplied using the `-kvfile` command-line argument. Lines the form "<name>=<value>" are then read from this file and added to the list of named values that can be displayed using the `$(name)` notation. The other method is via a unix-filesystem socket. The path to the socket is specified with the '-sock' command-line option, and then values can be written to it in the line-by-line format "<name>=<value>" (so the same as for the key-value files). Both files and the socket method expect a single "<name>=<value>" per line, and expect lines to be terminated with a line-feed character.

Both `-kvfile` and `-sock` support special name-value pairs whose name begins with '@'. These are treated as counters, so that instead of storing the sent value, the counter increments. If a blank string is sent as the value, the counter will reset to zero. 

Both `-kvfile` and `-sock` support special name-value pairs whose name begins with '>'. These work like the counters above, but in addition are stored as lists in files at '~/.barmaid/<name>.lst'. An on-click can then be used to launch some program that will display the list.  If a blank string is sent as the value the counter will reset to zero and the list will be cleared. 





ANIMATIONS
==========

Since barmaid v6.5 simple text animations are supported. They are defined as comma-seperated lists of strings like so:


```
~a{1,2,3,4}
```

This animation would count from 1 to 4 over and over. 

These are normally used in Value Translations, for instance to have an animation that plays when a battery is charging.


Clever use of selected chars can create text spinners, bubblers, etc


```
~a{\,|./,-}                               - classic 'spinner'
~a{.,o,O}                                 - 'bubbler'
~a{|---,-|--,--|-,---|,--|-,-|--,|---}    - line that sweeps back and forth
```

However a monospace font is usually needed for such animations to look good.


Color codes like '~r' can be used in animations:

```
~a{~r-~0--,-~r-~0-,--~r-~0,-~r-~0-}       - 'knight rider' red bar that moves back and forth
```


MODULES
=======

Since version 3.0 barmaid supports modules. These are small lua scripts placed in a directory (default path /usr/local/lib/barmaid/:/usr/lib/barmaid:~/.local/lib/barmaid) that can be used to extend barmaid's functionality. Two types of module exist: 'Information modules' that add new types of information to be displayed, and 'Reformat modules' that color, translate or otherwise modify the values to be displayed. 

Two example information  modules already exist 'aurorawatch.lua' and 'isc.lua', displaying the aurorawatch status and Internet Storm Center Threat Level respectively. Modules work by putting an object into the table 'lookup_modules'. This object must have a '.init' function. This function will be called and passed a 'lookups' table and a 'display string'. This string contains all the variables that are needed to display the bar. The module should check if the name of the variable it will provide is in the string, and if so add a 'lookup' function to the supplied 'lookups' table. This lookup function will then be called when the data is needed. The module should get the data and put it into the table 'display_values' under the name that it will be called as. For instance, the Internet Storm Center threat level can be looked up via the variable '$(isc)' and so it's value is put into the 'display_values' table like this:

```
	display_values["isc"]=value
```

Some values, particularly those looked up via the internet, should not be looked up on every call of the lookup function. To assist with this there's a global 'lookup_counter' value that counts seconds since program startup. 

'Reformat' modules are modules intended for the use of changing the displayed value that's output to the bar. Instead of being added to 'lookup_modules' table the object is added to the 'display_modules' table. The don't need an 'init' function, and the object aded to the 'display_modules' table only needs to contain as single function called 'process'. This function is called for every lookup value/type, and is passed the variables 'name' and 'value', representing the name and value of each variable that's going to be displayed. The function either returns 'value' unchanged, or else return some kind of translated value.

An example 'reformat' module is also provided in the distribution.


CONFIG FILE
===========

By default barmaid looks for config files in `~/.config/barmaid.lua/barmaid.conf`, `~/.config/barmaid.conf`, `~/.barmaid.conf` and `/etc/barmaid.conf`. The '-c' command-line option allows changing this search path, like so:

```
  barmaid.lua -c /config/barmaid.conf:~/etc/barmaid.conf:/usr/local/etc/barmaid.conf
```
The config file contains entries of the form:                                                                                      

```
  <config type> <value>
```  

Possible config types are:

display
: string to be displayed in the bar (multiple can be configured and cycled through)
display-string
: string to be displayed in the bar (multiple can be configured and cycled through)
display_cycle_time
: when multiple display strings are configured, cycle between them at interval defined in seconds
output
: output type, 'dzen2', 'lemonbar', 'dwm', etc
outtype
: output type, 'dzen2', 'lemonbar', 'dwm', etc
xpos
: x-position, can be 'left', 'right', 'center' or a pixel-position
ypos
: y-position, can be 'left', 'right', 'center' or a pixel-position
width
: bar width in pixels
height
: bar height in pixels
align
: text alignment, can be 'left', 'right' or 'center'
font
: name of font to use in the bar
fn
: name of font to use in the bar
foreground
: default foreground color
fg
: default foreground color
background
: default background color
bg
: default background color
translate
: translate a value to another (see --help-translations)
tr
: translate a value to another (see --help-translations)
kvfile
: path to a key-value file
icon-path
: colon-separated search path to find icons
icon_path
: colon-separated search path to find icons
iconpath
: colon-separated search path to find icons
datasock
: path to a datasocket to receive key=value messages on
onclick
: configure an 'onclick' (see --help-onclick)

An example config file is supplied with the program code




