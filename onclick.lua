
onclicks=
{
items={},

add=function(self, value)
local toks, tok
local click={}

toks=strutil.TOKENIZER(value, "|")

click.left=toks:next()
click.middle=toks:next()
click.right=toks:next()

table.insert(self.items, click)

end,



get=function(self, display_id, onclick_id)
local item, str

str=tostring(display_id) .. ":" .. tostring(onclick_id)
item=self.items[str]
if item==nil then return nil end

return item
end,



get_button=function(self, displayno, index, button)
local click

click=self:get(displayno, index)

if click ~= nil
then
	if button == "left" then return click.left 
	elseif button == "middle" then return click.middle
	elseif button == "right" then return click.right
	end
end

return ""
end,


init_displaystr=function(self, item_pos, item_list, display_id, display_str)
local toks, tok, str
local onclick_count=0

toks=strutil.TOKENIZER(display_str, "~{", "ms")
tok=toks:next()
while tok ~= nil
do
  if tok == "~{" 
  then
    str=tostring(display_id) .. ":" .. tostring(onclick_count)
    item_pos = item_pos + 1
    onclick_count=onclick_count + 1
    self.items[str]=item_list[item_pos]
  end

  tok=toks:next()
end

return item_pos
end,


init=function(self)
local list, dstr
local pos=0
local display_id=0

list=self.items
self.items={}

dstr=display:first()
while dstr ~= nil
do
pos=self:init_displaystr(pos, list, display_id, dstr)
display_id=display_id + 1
dstr=display:next()
end

end
}
