
function OnClickAdd(value)
local toks, tok
local click={}

toks=strutil.TOKENIZER(value, "|")

click.left=toks:next()
click.middle=toks:next()
click.right=toks:next()

table.insert(settings.onclicks, click)

end

function OnClickGet(index, button)
return settings.onclicks[index]
end

function OnClickGetButton(index, button)
local click

click=settings.onclicks[index]
if click ~= nil
then
	if button == "left" then return click.left 
	elseif button == "middle" then return click.middle
	elseif button == "right" then return click.right
	end
end

return ""
end
