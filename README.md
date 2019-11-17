Barmaid.lua - a status bar tool for dzen2, lemonbar and the terminal
====================================================================

SYNOPSIS
========

barmaid.lua is a status-bar generation program written in lua using libUseful-lua. It can generate output suitable for dzen2, lemonbar and the terminal. It can display infor on date, time, system load, memory usage, partition usage, cpu usage, ip4 address/netmask/broadcast, hostname, kernel, architecture, ostype, uptime, cpu count, battery level, and cpu temperature. No external programs are run to generate this data, so barmaid's resource usage should be low. Unfortuantely, as barmaid pulls a lot of data from /proc and /sys, it's a mostly linux-only program.

INSTALL
=======

You'll need to install libUseful (https://github.com/ColumPaget/libUseful) and libUseful-lua (https://github.com/ColumPaget/libUseful-lua) 

USAGE
======

```
lua barmaid.lua [-t output_type] [-x xpos] [-y ypos] [-w width] [-h height] [-bg color] [-fg color] [-fn font] [-font font] [format string]
```

the `-t` option sets the output type, which can be 'dzen2', 'lemonbar' or 'terminal'. The `-x`, `-y`, `-w` and `-h` options set the x and y position of the bar, and its width and height, in pixels. The `-x` position option can also accept 'left', 'right' and 'center' as screen positions. The `-bg` and `-fg` options set the foreground and background colors of the bar, which is expressed in rrggbb hexadecimal format with or without a leading '#' (if using a '#' you'll have to put the color string in single-quotes or the shell will treat it as a comment). `-fn` and `-font` set the font to use, this can differ a bit in format with dzen2 accepting short fontconfig names, whereas lemonbar uses old-style X11 font names (use xlsfonts to see a list of these for your system).

Finally the `format string` is the string to display. Values within `$()` will be substituted by the program with the appropriate data, like this:

```
	$(time) $(hostname) $(fs:/) $(date)
```

Colors can be set using libUseful `~` notation, where the next character is the color prefix. Available colors are:

```
~w  white
~n  black 
~b  blue
~c  cyan
~g  green
~y  yellow
~m  magenta
~r  red
~0  reset to default color
```
The uppercase version of these sets the background instead of the foreground color. 


So, for example:

```
		~bdisk:~0 $(fs:/)  ~bmem:~0 $(mem)
```

Will display the words 'disk:' and 'mem:' in blue, in front of the values for root-partition usage and memory usage, which will be in the default color.

Some values, like filesystem or cpu usage, automatically color themselves green/yellow/red to indicate severity.


Available value names that can be included in the format string are:

```
time           display time as %H:%M:%S
date           display date as %Y/%m/%d
day_name       display 3-letter day name (Sun, Mon, Tues...)
month_name     display 3-letter month name
hour        
minutes
seconds
year
month
day
hostname       system hostname
arch           system architecture
os             system os type
kernel         kernel version number
uptime         system uptime in $H:%M:%S
cpu_count      number of cpus
bat:           display percentage remaining battery. This requires a battery number suffix, so `$(bat:0)` for the first battery
charging:      returns the character '~' (to look like an 'AC' symbol) if battery is charging. Requires a battery number suffix
fs:            display filesystem use percent. Requires a filesystem mount suffix, so `$(fs:/home)` for filesystem on /home
ip4address:    display ip4address. Requires a network interface suffix, e.g. `$(ip4address:eth0)`
ip4netmask:    display ip4address. Requires a network interface suffix, e.g. `$(ip4address:eth0)`
ip4broadcast:  display ip4address. Requires a network interface suffix, e.g. `$(ip4address:eth0)`
cpu_temp       display cpu temperature in celsius. Currently only works on systems that have x86_pkg_temp type sensors.
load_percent   system percentage load

```
