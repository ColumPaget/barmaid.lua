-- functions relating to the unix socket that we can receive key-value messages on

function DataSockAdd(path)
local Serv

Serv=net.SERVER("unix:"..path, "perms=0666")
if Serv ~= nil 
then 
  datasock=Serv
  poll_streams:add(Serv:get_stream())
end

end


