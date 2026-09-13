flagfiles={

lookup_flagfile=function(self, path)
local mtime

if filesys.exists(path) == true 
then
   display_values["flagfile:"..path]="y"
   
   mtime=filesys.mtime(path) 
   if mtime ~= nil and mtime > 0
   then 
     diff=time.secs() - mtime
     display_values["flagfile_age:"..path]=time.format_duration("high+1", diff) 
     
     display_values["flagfile_mtime:"..path]=time.formatsecs("%Y-%m-%d %H:%M:%S", mtime) 
     if diff < (24 * 3600) then display_values["flagfile_when:"..path]=time.formatsecs("%H:%M:%S", mtime) 
     else display_values["flagfile_when:"..path]=time.formatsecs("%Y-%m-%d", mtime) 
     end
   end
else 
display_values["flagfile:"..path]="n"
end

end,




lookup=function(self, fmtstr)
local i, lookup, host, str
local flagfile_paths={}

toks=strutil.TOKENIZER(fmtstr, "$(|^(|:|)", "ms")
str=toks:next()
while str ~= nil
do
	if str == "flagfile"  or str == "flagfile_when" or str == "flagfile_age" or str == "flagfile_mtime"
	then 
	toks:next() -- will be ':' sepearator
	table.insert(flagfile_paths, toks:next())
	end
str=toks:next()
end

for i,str in ipairs(flagfile_paths)
do
	self:lookup_flagfile(str)
end

end

}


function FlagFileLookup(fmtstr)

flagfiles:lookup(fmtstr)
end
