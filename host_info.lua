
function LookupHostInfo()
local val

display_values["hostname"]=sys.hostname()
display_values["kernel"]=sys.release()
display_values["arch"]=sys.arch()
display_values["os"]=sys.type()

val=sys.uptime()
if val / (3600 * 365) > 1
then
  display_values["uptime"]=time.formatsecs("%y years %j days %H:%M:%S", val, "GMT")
elseif val / (3600 * 24) > 1
then
  display_values["uptime"]=time.formatsecs("%j days %H:%M:%S", val, "GMT")
else
  display_values["uptime"]=time.formatsecs("%H:%M:%S", val, "GMT")
end

LookupMemInfo();
end

