-- functions relating to outputting to the title bar of an xterm

-- build escape sequence to set text in xterm title bar
function XtermTitleTranslateOutput(str)
return("\x1b]2;" .. MonochromeTranslateOutput(str) ..  "\x07")
end



