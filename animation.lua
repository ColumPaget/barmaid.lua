--[[

functions related to simple text animations. These are declared as
comma-separated lists like so:


~a{1,2,3,4}

the above would cause the displayed value to march from 1 to 4 over and over
for as long as the animation is active. Other effects can be obtained with
clever use of characters, e.g.

~a{\,|,/,-,}

should create a classic 'spinner' and

~a{.,o,O} 

should create a 'bubbling' effect

However, it's important to use monospaced fonts to get good results

Color tags like ~r, or ~g can be used in these animations:

~a{~r-~0--,-~r-~0,--~r-~0,-~r-~0-}

Gives a 'knight rider' effect with a single red '-' sliding back and forth


]]--



animations={

--animations.tick() returns the next string in the animation
tick=function(self, anim, pos)
local toks, str, i
local count=0

toks=strutil.TOKENIZER(anim, ",", "q")
str=toks:next()
while str
do
count = count + 1
str=toks:next()
end

if count > 0 then count = pos % count end

toks=strutil.TOKENIZER(anim, ",", "q")
for i=0,count,1
do
str=toks:next()
end

return str
end,


-- find ~a{...} stanzas in an input string and process them
process=function(self, input, pos)
local toks, str 
local output=""

toks=strutil.TOKENIZER(input, "~a{|}", "ms")
str=toks:next()
while str
do
  if str == "~a{"
  then
		str=toks:next()
		output=output .. self:tick(str, pos)
		toks:next() -- remove finishing '}'
  else output=output .. str
  end
str=toks:next()
end


return output
end

}
