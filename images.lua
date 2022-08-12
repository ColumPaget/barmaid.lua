--functions related to loading images that are used with bars like dzen2 and lemonbar that support this feature

--checks if a .xpm version of an image has been cached in ~/.local/share/cache/icons
--and uses ImageMagick 'convert' utility to create one if not
function ConvertImageToXPM(path)
local extn, str

extn=filesys.extn(path)
if extn==".xpm" then return path end 

str=string.gsub(filesys.basename(path), extn, ".xpm")
cache_path=process.getenv("HOME") .. "/.local/share/cache/icons/" .. str
if filesys.exists(cache_path) then return cache_path end

filesys.mkdirPath(cache_path)
os.execute("convert "..path.." "..cache_path)

return cache_path
end


-- clips out an image path from a '~i{path}' display string entry
function TranslateClipImagePath(str, i)
local val, item

i=i+2
val=string.find(string.sub(str, i), "}")
item=string.sub(str, i, i+val-2)

if string.sub(item, 1, 1) ~= '/'
then
	item=filesys.find(item, settings.icon_path)
end

if filesys.exists(item) == true 
then 
item=ConvertImageToXPM(item) 
else
item=nil
end


i=i+val-1

return i,item
end


