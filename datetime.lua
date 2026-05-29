-- functions related to lookups of date and time


function LookupTimezones(fmt_str)
local toks, str
local parts={}

toks=strutil.TOKENIZER(fmt_str, "$(|^(|:|)", "ms")
str=toks:next()
while str ~= nil
do
  if str=="$(" or str=="^("
  then
    str=toks:next()
    if str=="tztime" or str=="tzdate"
    then
    str=toks:next() --consume the ':'
    str=toks:next()
		display_values["tzdate:"..str]=time.format("%Y/%m:%d", str)
		display_values["tztime:"..str]=time.format("%H:%M:%S", str)
    end
  end
  str=toks:next()
end

return parts
end
 

function LookupTimes(fmt_str)
  display_values.time=time.format("%H:%M:%S")
  display_values.date=time.format("%Y/%m/%d")
  display_values.day_name=time.format("%a")
  display_values.month_name=time.format("%b")
  display_values.hour=time.format("%H")
  display_values.minutes=time.format("%M")
  display_values.seconds=time.format("%S")
  display_values.year=time.format("%Y")
  display_values.month=time.format("%m")
  display_values.day=time.format("%d")
	LookupTimezones(fmt_str)
end


