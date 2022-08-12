-- These functions all relate to bars displayed in the terminal using vt100/ansi escape sequences


-- convert a display string to vt/ansi color codes
function TerminalTranslateOutput(settings, input)
local str

if strutil.strlen(settings.term_background) > 0 then input=settings.term_background .. string.gsub(input, "~0", "~0".. settings.term_background) end
if strutil.strlen(settings.term_foreground) > 0 then input=settings.term_foreground .. string.gsub(input, "~0", "~0".. settings.term_foreground) end

str="\r" .. input .. "~>~0"
if settings.ypos=="bottom" 
then 
  str=string.format("\x1b[s\x1b[%d;0H%s\x1b[u", term:length(), str)
end
return(terminal.format(str))
end



-- Before this function is called, the user is running a shell on a pty. Then they run barmaid. barmaid then opens a 
-- new shell in a pty, thus 'wrapping' the terminal/shell/pty and interjecting itself between the user and the shell/pty. 
-- Barmaid can now inject text and escape sequences into the stream of characters coming from the shell, allowing it to 
-- decorate the terminal by using escape sequences to set the xterm title, or create a text bar at the bottom of the screen.
function TerminalWrap(steal_lines)
-- stdio, shell and term are all global because
-- we access them on events

  stdio=stream.STREAM("-")
  shell=stream.STREAM("cmd:/bin/sh", "pty echo")
  term=terminal.TERM(stdio)
  if (steal_lines > 0)
  then  
    term:scrollingregion(0, term:length() -1)
    term:clear()
  end

  shell:ptysize(term:width(), term:length() - steal_lines)
  shell:timeout(10)
  poll_streams:add(shell)
  poll_streams:add(stdio)
  return stdio
end


--this function reads from the pty/shell if we are in terminal mode and have 
--spawned off a subshell to decorate with a bar
function TerminalReadFromPty()
local ch, seq_cls_len
local seq_cls=string.char(27) .. "[2J"
local seq_count=1
local retval=SHELL_OKAY

  seq_cls_len=string.len(seq_cls)
  ch=shell:readbyte();
  if ch ==-1 then return SHELL_CLOSED end

  while ch > -1
  do
    stdio:write(string.char(ch), 1) 

    if seq_count >= seq_cls_len 
    then
      retval=SHELL_CLS
    elseif string.sub(seq_cls, 1, 1) == string.char(ch) 
    then
      seq_count=seq_count+1
    end

    ch=shell:readbyte();
  end

  shell:flush()
  return retval
end

