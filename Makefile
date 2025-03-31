PREFIX=/usr/local
UNITS=common.lua colors.lua animation.lua images.lua dzen.lua lemonbar.lua terminal_bar.lua generic_bar.lua xterm_title.lua x11.lua output_types.lua sysfs.lua key_value.lua datasock.lua translate_values.lua onclick.lua settings.lua help.lua battery.lua cpu_use.lua memory_use.lua network.lua partitions.lua temperature.lua host_info.lua datetime.lua modules.lua main.lua

all: $(UNITS)
	cat $(UNITS) > barmaid.lua
	chmod a+x barmaid.lua
	@echo
	@echo "now 'make install' to install in home directory of current user or..."
	@echo "'make install_system' to install in /usr/local (you will likely need to be root to do this)"

install:
	mkdir -p ~/bin
	cp barmaid.lua ~/bin
	mkdir -p ~/.config/barmaid.lua
	cp *.conf ~/.config/barmaid.lua/
	mkdir -p ~/.local/lib/barmaid/
	cp modules/*.lua ~/.local/lib/barmaid/

install_system:
	mkdir -p $(PREFIX)/bin
	cp barmaid.lua $(PREFIX)/bin
	mkdir -p $(PREFIX)/lib/barmaid
	cp modules/*.lua $(PREFIX)/lib/barmaid/
