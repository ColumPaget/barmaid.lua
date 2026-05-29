-- this module holds functions that relate to the actual display of
-- text/values in the bar


display={

display_list_size=0,
display_tick=0, -- display tick is used by display cycling on the bar
list_pos=0,     -- list_pos is only used by 'first()' and 'next()' when we want to examine stored displays
display_list={},
alert_list={},


add=function(self, display_str)
self.display_list[self.display_list_size+1]=display_str
self.display_list_size=self.display_list_size + 1 
end,


count=function(self)
return(self.display_list_size)
end,

curr_num=function(self)
return(self.display_tick % self.display_list_size)
end,

add_alert=function(self, name, display_str)
alert={}


if self.alert_list[name] == nil
then
alert.expire=nil
alert.text=display_str

self.alert_list[name]=alert
end

end,


alerts_clear=function(self)
self.alert_list={}
end,

cycle=function(self)
self.display_tick = self.display_tick + 1
display_update_required = true
end,


first=function(self)
if self.display_list_size == 0 then return nil end
self.list_pos=1
return self.display_list[self.list_pos]
end,


next=function(self)
if self.display_list_size == 0 then return nil end

self.list_pos=self.list_pos + 1
if self.list_pos > self.display_list_size then return nil end
return self.display_list[self.list_pos]
end,


get_curr=function(self)
local pos, str, item
local count=0

for pos, item in pairs(self.alert_list)
do
if item.idle == nil then item.idle=lookup_counter+3 end
if item.expire == nil then item.expire=lookup_counter+6 end
if item.idle > lookup_counter then return item.text end
if item.expire < lookup_counter then self.alert_list[pos]=nil end
end


if self.display_list_size == 0 then return "" end

if settings.display_cycle_time > 0
then
if lookup_counter % settings.display_cycle_time == 0 then self:cycle() end
end

pos=self.display_tick % self.display_list_size
str=self.display_list[pos+1]
if str == nil then str=self.display_list[1] end

return str
end,


-- add a value to the list of current values, these values then get
-- substituted into the bar's display text
add_value=function(self, name, value, fmtstr, colormap)
local valstr

  if fmtstr ~= nil 
  then 
  valstr=string.format(fmtstr, value) 
  else
  valstr=value
  end

  display_values[name]=valstr
  if colormap ~= nil
  then
    display_values[name..":color"]=AutoColorValue(value, colormap)..valstr.."~0"
  end

end,



-- returns a table of values in the format
-- vars[name]=value
get_vars=function(self, fmt_str)
local vars={}
local toks, str

toks=strutil.TOKENIZER(fmt_str, "$(|^(|@(|>(|)", "ms")
str=toks:next()
while str ~= nil
do
  if str=="$(" or str=="@(" or str==">(" or str== "^(" then table.insert(vars, str..toks:next()..")") end
  str=toks:next()
end

return vars
end,




-- this function adds lookup functions to the 'lookups' table
-- using the badly named 'name' variable which contains the name 
-- of a lookup as it appeared in the main config string for the
-- display bar
initialize_lookup=function(self, lookups, name)
local check_names={}
local prefix

-- set any counter vars to zero initially, so that when the lookup
-- function is called it's counting from the right value!
prefix=string.sub(name, 1, 1)
name=string.sub(name, 3, string.len(name) -1)

if prefix=="@" 
then
  display_values[name]=0 
elseif prefix==">" 
then 
  display_values[name]=0 
  KvUpdateListFile(name, value)
end



check_names={["time"]=1, ["date"]=1, ["day_name"]=1, ["day"]=1, ["month"]=1, ["month_name"]=1, ["year"]=1, ["hours"]=1, ["minutes"]=1, ["mins"]=1, ["seconds"]=1, ["secs"]=1}


if check_names[name] ~= nil or string.sub(name, 1, 6) == "tztime" or string.sub(name, 1, 6) == "tzdate"
then
    table.insert(self.lookups, LookupTimes)
end

if string.sub(name, 1, 4) == "bat:" or string.sub(name, 1, 5) == "bats:"
then
  table.insert(self.lookups, LookupBatteries)
end

if string.sub(name, 1,3) == "fs:"
then
  table.insert(self.lookups, LookupPartitions)
end

if string.sub(name, 1, 8) == "cpu_temp"
then
  table.insert(self.lookups, LookupTemperatures)
end

if name == "cpu_count" or string.sub(name, 1, 4) == "load"
then
  table.insert(self.lookups, CpuUsage)
end

if string.sub(name, 1, 9) == "cpu_freq:"
then
  table.insert(self.lookups, CpuFreq)
end


if string.sub(name, 1, 4) == "load"
then
  table.insert(self.lookups, LookupLoad)
end

if string.sub(name, 1, 3) == "ip4"
then
  table.insert(self.lookups, LookupIPv4)
end

if string.sub(name, 1, 3) == "up:"
then
  table.insert(self.lookups, LookupServicesUp)
  if lookup_values.ServicesUp == nil then lookup_values.ServicesUp={} end
  table.insert(lookup_values.ServicesUp, string.sub(name, 4))
end

if string.sub(name, 1, 4) == "dns:" or string.sub(name,1,6)=="dnsup:"
then
  table.insert(self.lookups, LookupDNS)
  if lookup_values.DNSLookups == nil then lookup_values.DNSLookups={} end
  table.insert(lookup_values.DNSLookups, name)
end
end,


-- this function checks which values have been asked for in a display string, and adds the functions needed to look
-- those items up into the 'lookups' table.
extract_lookups=function(self, display_str)
local var_names

var_names=self:get_vars(display_str)

for i, var in ipairs(var_names)
do
self:initialize_lookup(self.lookups, var)
end

for i,mod in ipairs(lookup_modules)
do
  mod:init(self.lookups, display_str)
end

end,




--this function does the actual building of the output string
--it first calls all the lookups to get up-to-date values, then
--builds an output string using those values and does any
--display translation
substitute_values=function(self, settings)
local toks, str, func, feed
local output=""
local curr_display=""


curr_display=self:get_curr()

-- read up to date values from any key-value files
for i,feed in ipairs(settings.datafeeds)
do
  if feed.type=="kvfile" then KvFileRead(feed) end
end


-- call all lookup functions to get up to date values
for i,func in ipairs(self.lookups)
do
  func(curr_display)
end


-- go through display string extracting any variables and
-- substituting them for up-to-date values
toks=strutil.TOKENIZER(curr_display, "$(|^(|@(|>(|)|~a{|}", "ms")
str=toks:next()
while str ~= nil
do
if strutil.strlen(str) > 0
then
	-- these are various types of variable
  if str=="$(" or str=="^(" or str=="@(" or str==">("
  then
    str=toks:next()
    if display_values[str] ~= nil 
    then 
      output=output .. display_translations:process(str, display_values[str])
    end
  elseif str ~= ")"
  then
    output=output..str
  end
end
  str=toks:next()
end



output=animations:process(output, lookup_counter)
if string.find(output, '%(') ~= nil then io.stderr:write("ERR: ["..output.."]\n") end

return output
end,



init=function(self)
local i, key, fmt_str

self.lookups={}
-- always lookup basic host details
table.insert(self.lookups, LookupHostInfo)

for i, fmt_str in ipairs(self.display_list)
do
display:extract_lookups(fmt_str)
end


end

}


