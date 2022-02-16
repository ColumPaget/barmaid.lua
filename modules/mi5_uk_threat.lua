-- This module gets MI5's UK terrorism/security-threat status
-- use it by adding $(mi5) to your display string
-- there are five levels
--    LOW: means an attack is highly unlikely
--    MODERATE: means an attack is possible, but not likely
--    SUBSTANTIAL: means an attack is likely
--    SEVERE: means an attack is highly likely
--    CRITICAL: means an attack is highly likely in the near future



mod={}
table.insert(lookup_modules, mod)

-- module init function, setup module and insert it into module table
mod.init=function(self, lookups, display_str)
if string.find(display_str, "$%(mi5%)") ~= nil
then
        table.insert(lookups, self.lookup)
end

end


-- module lookup function, do the actual looking up and insert the result
-- into the 'display_values' table
mod.lookup=function(self)
local S, P, I, name, str

if lookup_counter % 60 == 0
then
S=stream.STREAM( "https://www.mi5.gov.uk/UKThreatLevel/UKThreatLevel.xml", "r")
if S ~= nil
then
        str=S:readdoc()
	P=dataparser.PARSER("rss", str)
        S:close()

	str=""
	if P ~= nil
	then
		I=P:next()
		while I ~= nil
		do
			name=I:name()
			if string.sub(name, 1,5)=="item:" then str=I:value("title") end
			I=P:next()
		end

		-- str will be: 'Current Threat Level: SEVERE' so we clip it down
		if strutil.strlen(str) > 22 
		then 
			str=string.sub(str, 23) 
			display_values["mi5"]=strutil.trim(str)
		end
	end

end
end

end

