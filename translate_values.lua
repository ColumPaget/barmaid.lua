-- these functions relate to the translation system that translates an output value to some other
-- display value


function DisplayTranslations()
translations={}

translations.by_name={}
translations.by_pattern={}


translations.lookup=function(self, str)
local item, pattern

item=self.by_name[str]
if item ~= nil then return item end

for pattern,item in pairs (self.by_pattern)
do
  if strutil.pmatch(pattern, str) == true then return item end
end

return nil
end


translations.process=function(self, value_name, ivalue)
local i, item, value, translate, str

value=ivalue

-- first we consider display modules, which are modules that can translate
-- a string into another before it's displayed
for i,item in ipairs(display_modules)
do
  if item.process ~= nil then value=item.process(value_name, value) end
end

-- 'value' is now either a copy of the original passed-in ivalue or
-- the result of a display-module changing it. We now look this value up
-- in our table of translations to see if we want it translated to another string

--first look to see if there's a translation for value_name=value
str=value_name.."="..value
translate=self:lookup(str)
if translate==nil then translate=self:lookup(value) end
if translate ~= nil then value=translate end

return value
end


translations.add=function(self, pattern, value)

if string.find(pattern, "[*+?%[%]]") ~= nil
then
  self.by_pattern[pattern]=value
else
  self.by_name[pattern]=value
end

end

-- parse a translation of a display output. This is a mapping of a string outputted by a value into
-- another string. Both strings can include ~ formatting, so for instance it's possible to translate
-- a string into an image like so:
-- -tr 'yes:~i{/usr/share/images/ok.jpg}'
translations.parse=function(self, def)
local toks, str

toks=strutil.TOKENIZER(def, "|")
str=toks:next()
if str ~= nil 
then 
  self:add(str, toks:remaining())
end

end


return translations
end

