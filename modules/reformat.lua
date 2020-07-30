

function Reformat(name, value)
if name=="isc"
then
	if value=="green" then value="~g~:happyface:~0"
	elseif value=="red" then value="~r~:radiation:~0"
	else value="~y~:warning:~0"
	end
end

if name=="aurorawatch"
then
	if value=="green" then value="~g~:fillcircle:~0"
	elseif value=="red" then value="~r~:fillcircle:~0"
	else value="~y~:fillcircle:~0"
	end
end

return value
end


mod={}
mod.process=Reformat
table.insert(display_modules, mod)
