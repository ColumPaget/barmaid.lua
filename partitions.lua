-- functions related to lookups of filesystems/partitions 

function LookupPartitionsGetList()
local toks, str
local parts={}

toks=strutil.TOKENIZER(settings.display, "$(|^(|:|)", "ms")
str=toks:next()
while str ~= nil
do
  if str=="$(" or str=="^("
  then
    str=toks:next()
    if str=="fs"
    then
    str=toks:next() --consume the ':'
    str=toks:next()
    parts[str]="y"
    end
  end
  str=toks:next()
end

return parts
end
  

function LookupPartitions()
local str, perc, color, toks
local S, requested_partitions


requested_partitions=LookupPartitionsGetList()

S=stream.STREAM("/proc/self/mounts", "r")
if S ~= nil
then

  str=S:readln()
  while str ~= nil
  do
    toks=strutil.TOKENIZER(str, "\\S")
    fs_type=toks:next()
    fs_mount=toks:next()

    if fs_type ~= "none" and fs_type ~="cgroups" and requested_partitions[fs_mount] ~= nil
    then
      perc=math.floor( (filesys.fs_used(fs_mount) * 100 / filesys.fs_size(fs_mount)) + 0.5)
      AddDisplayValue("fs:"..fs_mount, perc, nil, usage_color_map)
    end

  str=S:readln()
  end

  S:close()
end


return str
end

