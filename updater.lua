updater={

update_mods={},
next_lookup=0,
S=nil,
proc=nil,


get_stream=function(self)
return self.S
end,

-- is an update run required?
required=function(self, now)

if #self.update_mods == 0 then return false end

--if self.S exists, then a process is already running
if self.S ~= nil then return false end

if now > self.next_lookup then return true end

return false
end,


-- add a module to be updated 
add_mod=function(self, mod)
table.insert(self.update_mods, mod)
end,


process_input=function(self)
local line, toks, key, value

if self.S ~= nil 
then
   line=self.S:readln()
   if line == nil  
   then 
     poll_streams:delete(self.S)
     self.S:close()
     self.S=nil
     self.proc=nil
   return false 
   end
   
   toks=strutil.TOKENIZER(strutil.trim(line), "=")
   key=toks:next()
   value=toks:remaining()
   if key ~= nil then display_values[key]=value end
end

return true
end,


--do an actual update run, querying data from modules
run=function(self)
local i, mod

for i,mod in ipairs(self.update_mods)
do
mod:lookup()
end

end,


--launch a new update process
launch=function(self)


if self.S == nil 
then
  self.proc=process.PROCESS("", "stderr2null")
  if self.proc == nil
  then
    self:run()
    os.exit()
  else
    self.next_lookup=time.secs() + settings.updater_run
    self.S=self.proc:get_stream()
    if self.S ~= nil then poll_streams:add(self.S) end
  end
end

return self.S
end


}
