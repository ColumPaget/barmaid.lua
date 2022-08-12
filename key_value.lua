-- functions related to key-value messages sent to us from other programs

function KvUpdateCounter(name, value)
local val

if strutil.strlen(value)==0
then 
  val=0
elseif display_values[name] ~= nil 
then 
  val=tonumber(display_values[name]) +1
else 
  val=1 
end

display_values[name]=val
end


function KvUpdateListFile(name, value)
local S, path, mode

path=process.getenv("HOME").."/.barmaid/"..name..".lst"
filesys.mkdirPath(path)
if strutil.strlen(value) == 0 then mode="w"
else mode="a" 
end

S=stream.STREAM(path, mode)
if S ~= nil
then
if strutil.strlen(value) > 0 then S:writeln(value.."\n") end
S:close()
end

end


function KvLineRead(S)
local line, str, toks, prefix, name, value

line=S:readln()

if line ~= nil
then
  line=strutil.trim(line)

  if string.len(line) > 0
  then
  toks=strutil.TOKENIZER(line, "=")
  str=toks:next()
  prefix=string.sub(str, 1, 1)
  name=string.sub(str, 2)
  value=toks:remaining()

  if prefix=="@"
  then
    KvUpdateCounter(name, value)
  elseif prefix==">"
  then
    KvUpdateCounter(name, value)
    KvUpdateListFile(name, value)
  else -- if prefix isn't a prefix char, then name is the whole of 'str'
    display_values[str]=toks:remaining()
  end
  end

  return true
else
  return false
end

end


function KvFileRead(feed)
local S

S=stream.STREAM(feed.path)
if S ~= nil
then
  while KvLineRead(S)
  do
    --nothing
  end
  S:close()
end
end


function KvFileAdd(path)
local S 
local feed={}

feed.type="kvfile"
feed.path=path
feed.read=KvFileRead
table.insert(settings.datafeeds, feed)

end


