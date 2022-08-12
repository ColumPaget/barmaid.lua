-- these functions relate to loading modules that add features or otherwise change the behavior of barmaid


function LoadModulesFromDir(dir)
local str, glob

  glob=filesys.GLOB(dir.."/*.lua")
  str=glob:next()
  while str ~= nil
  do
    dofile(str)
    str=glob:next()
  end
end

function LoadModules()
local toks, path

toks=strutil.TOKENIZER(settings.modules_dir, ":")
path=toks:next()
while path ~= nil
do
  if string.sub(path, 1, 1) == "~" then path=process.getenv("HOME") .. string.sub(path, 2) end


  if LoadModulesFromDir(path) then break end
  path=toks:next()
end
end

