

function AurorawatchLookup()
local S, doc, toks, tok, str

if lookup_counter % 240 == 0
then
S=stream.STREAM("http://aurorawatch-api.lancs.ac.uk/0.2/status/current-status.xml", "r")
if S ~= nil
then
	doc=S:readdoc()
	S:close()
end

if strutil.strlen(doc) > 0
then
toks=strutil.TOKENIZER(doc, "<|>|/|=| ", "mq")
tok=toks:next()
while tok ~= nil
do
	if tok=="status_id" then str=toks:next() end
	tok=toks:next()
end

str=strutil.stripQuotes(str)
display_values["aurorawatch"]=str
end
end

end


function AurorawatchInit(lookups, display_str)

if string.find(display_str, "$%(aurorawatch%)") ~= nil
then
	table.insert(lookups, AurorawatchLookup)
end

end


mod={}
mod.lookup=AurorawatchLookup
mod.init=AurorawatchInit
table.insert(lookup_modules, mod)
