-- functions related to displaying help to the user

function DisplayHelp()
print()
print("barmaid.lua  version: " .. version)
print()
print("usage:  lua barmaid.lua [options] [format string]")
print()
print("options:")
print("-c <path>          - path to config file")
print("-t <type>          - type of output. Possible values are 'dzen', 'lemonbar', 'xterm', 'dwm' and 'term'")
print("-x <pos>           - x-position of window, in pixels or 'left', 'right', 'center'")
print("-y <pos>           - y-position of window, in pixels or 'top', 'bottom'")
print("-w <width>         - width of window in pixels")
print("-h <height>        - height of window in pixels")
print("-align <alignment> - set text alignment, 'left', 'right' or 'center'")
print("-fn <font name>    - font to use")
print("-font <font name>  - font to use")
print("-bg <color>        - background color")
print("-fg <color>        - default font/foreground color")
print("-icon-path <path>  - colon seperated path in which to search for icons")
print("-tr <translation>  - translate a value to a different display value")
print("-kvfile <path>     - path to a file that contains name-value pairs")
print("-sock <path>       - path to a unix stream socket that receives name-value pairs")
print("-onclick <command> - register a command to be used in clickable areas (see -help-onclick)")
print("-help-colors       - list color switches recognized in format string")
print("-help-values       - list values recognized in format string")
print("-help-onclick      - explain clickable area system")
print("-help-images       - explain images display system")
print("-help-sock         - explain datasocket system")
print("-help-translate    - explain the value translate system")
print("-help-config       - explain config files")
print("-?                 - this help")
print("-help              - this help")
print("--help             - this help")
print()
print("example format string:")
print("  $(date) $(time)   mem used: $(mem)%  fs used: $(fs:/)%")
print("this format string must be enclosed in single quotes (') if passed on the command-line (rather than in config file), or the shell will eat it.")
print()
print("Alternatively the form '^(' can be used instead of '$(', allowing double-quotes to be used and shell vars to be passed. e.g.:")
print("  host: $HOST  ^(date) ^(time)    mem used: ^(mem)%  fs used: ^(fs:/)%")
print()
print("use '-help-values' to get a list of values that can be included in the format string, and '-help-colors' for a list of color-codes")
print()
os.exit(0)
end



function DisplayHelpColors()
print()
print("Colors within the format string can be set using libUseful `~` notation, where the next character is the color prefix. These are then translated for the target output type. Available colors are:")
print()
print("~w  white")
print("~n  black")
print("~b  blue")
print("~c  cyan")
print("~g  green")
print("~y  yellow")
print("~m  magenta")
print("~r  red")
print("~0  reset to default color")
print()
print("The uppercase version of these sets the background instead of the foreground color.")
print()
print("Example:  ~r this text in red ~0 ~w~BThis text white on a blue background~0")
print()
print("~i is a special case that allows the displaying of images in dzen2. See '-help-images'")
print("~{ and ~} are special cases that define clickable areas. See '-help-onclick'")

print("Some special values are available that automatically color themselves. See '-help-values'.") 
print()


os.exit(0)
end


function DisplayHelpValues()
print()
print("Values can be entered into the format string like this: ")
print("  temp:  $(cpu_temp)")
print()
print("The format string should be enclosed in single quotes (') or else the shell will clobber these values.")
print()
print("User-defined values (including counters) are possible, and can be set using the 'datasock' system (see -help-sock)")
print()
print("In addition to plain values, barmaid.lua has a number of 'auto-color' values with ':color' appended to their name, which automatically color themselves depending on the values they have.")
print()
print("Available plain values are:")
print()
print("time           display time as %H:%M:%S")
print("date           display date as %Y/%m/%d")
print("day_name       display 3-letter day name (Sun, Mon, Tues...)")
print("month_name     display 3-letter month name")
print("hour")
print("minutes")
print("seconds")
print("year")
print("month")
print("day")
print("hostname       system hostname")
print("arch           system architecture")
print("os             system os type")
print("kernel         kernel version number")
print("uptime         system uptime in $H:%M:%S")
print("cpu_count      number of cpus")
print("cpu_temp       cpu temperature in celsius. Currently only works on systems that have x86_pkg_temp or coretemp type sensors. For multicore systems displays the highest across all CPUs.")
print("mem            percent memory usage")
print("memuse         percent memory usage calculated from 'availmem' (see discussion below for difference to 'mem')")
print("usedmem        used memory in metric format")
print("freemem        free memory in metric format")
print("availmem       available memory in metric format (see below on difference to freemem)")
print("totalmem       total memory in metric format")
print("cachedmem      cached memory in metric format, this can include ramdisks etc")
print("swap           percent swap space usage")
print("usedswap       used swap in metric format")
print("freeswap       free swap in metric format")
print("totalswap      total swap in metric format")
print("bat:           percentage remaining battery. This requires a battery number suffix, so `$(bat:0)` for the first battery")
print("charging:      returns the character '~' (to look like an 'AC' symbol) if battery is charging. Requires a battery number suffix")
print("bats           info for all batteries. If no batteries present, this will be blank.")
print("fs:            filesystem use percent. Requires a filesystem mount suffix, so `$(fs:/home)` for filesystem on /home")
print("ip4address:    ip4address. Requires a network interface suffix, e.g. `$(ip4address:eth0)`")
print("ip4netmask:    ip4address. Requires a network interface suffix, e.g. `$(ip4address:eth0)`")
print("ip4broadcast:  ip4address. Requires a network interface suffix, e.g. `$(ip4address:eth0)`")
print("load_percent   system percentage load (instantaneous cpu usage)")
print("load           system load (instantaneous cpu usage) in 'top' format")
print("load1min       1min  load in 'top' format")
print("load5min       5min  load in 'top' format")
print("load15min      15min load in 'top' format")
print("")
print("Available auto-colored values are:")
print()
print("cpu_temp:color     cpu temperature in celsius. Currently only works on systems that have x86_pkg_temp or coretemp type sensors. For multicore systems displays the highest across all CPUs.")
print("cpu_freq:<cpuid>       cpu frequency for a specific cpu. <cpuid> has the form 'cpu0', 'cpu1' etc")
print("cpu_freq:avg           average cpu frequency across all cpus")
print("mem:color          percent memory usage")
print("memuse:color       percent memory usage using 'availmem' (see discussion below for difference from 'mem')")
print("free:color         percent memory free")
print("avail:color        percent memory available (see discussion below for difference from free)")
print("cmem:color         percent of memory that is cache")
print("swap:color         percent swap space usage")
print("usedswap:color     used swap in metric format")
print("freeswap:color     free swap in metric format")
print("totalswap:color    total swap in metric format")
print("bat:<name>:color   percentage remaining battery. This requires a battery number suffix, so `$(bat:0)` for the first battery")
print("bats:color         info for all batteries. If no batteries present, this will be blank.")
print("fs:<path>:color    filesystem use percent. Requires a filesystem mount suffix, so `$(fs:/home)` for filesystem on /home")
print("load_percent:color system percentage load (instantaneous cpu usage)")
print("load:color         system load (instantaneous cpu usage) in 'top' format")
print("load1min:color     1min  load in 'top' format")
print("load5min:color     5min  load in 'top' format")
print("load15min:color    15min load in 'top' format")
print("up:<host>:<port>   connect to service at 'host' and 'port'. display 'up' if connection succeeds, 'down' if not")
print("dns:<host>         lookup 'host' and return its IP address")
print("dnsup:<host>       lookup 'host' and return 'up' if a value is returned 'down' if not")

print("")

print("'freemem and 'availmem', 'free' and 'avail', and 'mem' and 'memuse' differ. ''freemem', free' and 'mem' are calcluated to align with the output of the command-line 'free' command. 'availmem', 'avail' and 'memuse' are calculated from the /proc/meminfo 'MemAvailable' entry. Usually there should be little difference between these, but one cause of a difference is ramdisks. If you have a tmpfs ramdisk on, say /tmp, and its consuming a lot of memory (perhaps because it contains large files) 'freemem' and 'mem' will show you have plenty of memory, even though you don't, as they will not be aware of memory consumed by the ramdisk. 'availmem' and 'memuse' will be a truer reflection of memory available. If you display both these values, and see a large difference between them, then perhaps you need to check your ramdisks!")

print("")

print("the ip4 values have a special case where the interface suffix is specified as 'default'. In this case the system will go with the first interface it finds that has an ip and isn't the local 'lo' interface")
print("")
print("the default format string is:")
print(settings.display)
print()
os.exit(0)
end


function DisplayHelpDatasocket()
print()
print("barmaid.lua can receive messages on a unix socket, specified with the '-sock' option. Messages sent to this socket can then be used to set variables in barmaid in order for them to be displayed. For example:")
print()
print("   barmaid.lua 'message: $(announcement)' -sock /tmp/barmaid.sock")
print()
print("messages can then be sent to this socket in the form 'announcement=system is shutting down' and the variable 'announcement' will be set and displayed. Messages must be terminated with a 'newline' character.") 
print()
print("A special type of variable with names begining with the '@' symbol can be used as a counter. For example:")
print()
print("   barmaid.lua 'events: $(@events)' -sock /tmp/barmaid.sock")
print()
print("will display a counter that can be incremented by sending '@events=something' to the datasocket. Every time such a message is recieved, the counter will increment. The counter can be reset to zero by setting the variable to an empty string by sending '@events='");
print()

os.exit(0)
end


function DisplayHelpImages()

print()
print("barmaid.lua can use images with the dzen2 bar utility. An entry in the display string of the form:")
print()
print("   ~i{/usr/share/icons/warning.jpg}")
print()
print("will display the image '/usr/share/icons/warning.jpg' in the dzen2 bar. Dzen2 only supports .xpm images by default, so barmaid.lua will use the ImageMagick 'convert' program to convert .png or .jpg files before displaying them.");
print()

os.exit(0)
end


function DisplayHelpOnClick()

print()
print("Clickable areas are supported for dzen2 and lemonbar bars. These are defined using ~{ and ~} to mark the start and the end of a clickable area. These areas then match to -onclick options given on the barmaid command line, or 'onclick' entries in the config file. The first '~{' in the display string matches the first -onclick option, and so on. For example:")
print()
print("   lua barmaid.lua '~{ 1st on click~}  ~{ 2nd on click ~}' -onclick xterm -onclick 'links -g www.google.com'")
print()
print("will create two clickable areas, the first of which will launch and xterm when clicked, and the second will launch the links webbrowser.");
print()
print("To achieve the same thing in the config file:")
print()
print("    display ~{ 1st on click~}  ~{ 2nd on click ~} ")
print("    onclick xterm ")
print("    onclick 'links -g www.google.com'")
print()
print("if it's desired to use the second and third mouse buttons to apply multiple click options to an area, then the pipe/bar symbol '|' can be used to add up to three actions:")
print()
print("    display ~{ 1st on click~}  ~{ 2nd on click ~} ")
print("    onclick xterm|rxvt|kitty ")
print("    onclick 'links -g www.google.com'||firefox")
print()
print("In this example left clicking (button 1) on '1st on click' will launch xterm, middle clicking (button 2) will launch rxvt, and right clicking (button 3) will launch kitty.")
print("Similarly left click on '2nd on click' will launch links, and right click will launch firefox.")
os.exit(0)
end



function DisplayHelpTranslate()

print()
print("There are a two ways to translate a datavalue into something else for display. For instance, some datavalues hold the string 'up' or 'down' to indictate the state of something. Translation modules are lua plug-ins used to perform this task and are not discussed here (see barmaid.lua's README.md file for details). The other method for translating such values is the '-tr' command-line option, or the 'translate' config-file option. In both cases this system uses a configuration string of the form:")
print()
print("  <value>|<translation>")
print()
print("So for example, the following:")
print()
print("  up|~g up ~0")
print()
print("Could be used to color the string 'up' in green (for clarity extra spaces are added around 'up' in the translation). This method could also be used to map 'up' to an icon:")
print()
print("  up|~i{/usr/share/icons/okay.jpg}")
print()
print("This would map all values that consist of the word 'up' to the specified icon.")
print()
print("Sometimes there's a need to specify which value is being translated. Multiple different data lookups could return the same value, and you might want to color them differently. This is achieved with:")
print()
print("  <name>=<value>|<translation>")
print()
print("Where 'name' is the name of a value, and 'value' is it's actual displayed result. E.g.")
print()
print("  up:google.com:80=up|~gG~0")
print()
print("Could be used to supply a green 'G' to indicate google is accessible, but not interfere with any other values that return 'up'")
print()
print("EXAMPLE:")
print()
print("  barmaid.lua 'dns:$(dnsup:google.com)  $(up:google.com:80) $(up:freshcode.club:80) $(up:kernel.org:80)' -tr 'dnsup:google.com=up|~gup~0' -tr 'dnsup:google.com=down|~rDOWN~0' -tr 'up:google.com:80=up|~gG~0' -tr 'up:freshcode.club:80=up|~gF~0' -tr 'up:kernel.org:80=up|~gK~0'")
print()
print("This allows mapping the value 'up' for different variables to different output strings (admittedly all of them green in color).")
print()

print()

os.exit(0)
end




function DisplayHelpConfig()
print("By default barmaid looks for default config files in ~/.config/barmaid.lua/barmaid.conf ~/.config/barmaid.conf, ~/.barmaid.conf and /etc/barmaid.conf. The '-c' command-line option allows changing this search path, like so:")
print()
print("  barmaid.lua -c /config/barmaid.conf:~/etc/barmaid.conf:/usr/local/etc/barmaid.conf")
print()
print("The config file contains entries of the form:")
print()
print("<config type> <value>")
print()
print("Possible config types are:")
print()
print("display            string to be displayed in the bar")
print("display-string     string to be displayed in the bar")
print("output             output type, 'dzen2', 'lemonbar', 'dwm', etc")
print("outtype            output type, 'dzen2', 'lemonbar', 'dwm', etc")
print("xpos               x-position, can be 'left', 'right', 'center' or a pixel-position")
print("ypos               y-position, can be 'left', 'right', 'center' or a pixel-position")
print("width              bar width in pixels")
print("height             bar height in pixels")
print("font               name of font to use in the bar")
print("fn                 name of font to use in the bar")
print("foreground         default foreground color")
print("fg                 default foreground color")
print("background         default background color")
print("bg                 default background color")
print("translate          translate a value to another (see --help-translations")
print("tr                 translate a value to another (see --help-translations")
print("kvfile             path to a key-value file")
print("icon-path          colon-separated search path to find icons")
print("icon_path          colon-separated search path to find icons")
print("iconpath           colon-separated search path to find icons")
print("datasock           path to a datasocket to receive key=value messages on")
print("onclick            configure an 'onclick' (see --help-onclick)")

os.exit(0)
end
