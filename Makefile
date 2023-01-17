UNITS=common.lua colors.lua images.lua dzen.lua lemonbar.lua terminal_bar.lua generic_bar.lua xterm_title.lua x11.lua output_types.lua sysfs.lua key_value.lua datasock.lua translate_values.lua onclick.lua settings.lua help.lua battery.lua cpu_use.lua memory_use.lua network.lua partitions.lua temperature.lua host_info.lua datetime.lua modules.lua main.lua

all: $(UNITS)
	cat $(UNITS) > barmaid.lua
	chmod a+x barmaid.lua
