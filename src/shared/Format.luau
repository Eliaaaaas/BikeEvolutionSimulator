--!strict
local Format = {}
local suffixes={"","K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"}
function Format.number(value: number): string
 if value~=value or math.abs(value)==math.huge then return "—" end
 local sign=if value<0 then "-" else ""
 value=math.abs(value)
 local group=if value<1000 then 0 else math.floor(math.log10(value)/3)
 if group>=#suffixes then return sign..string.format("%.2e",value) end
 local scaled=value/10^(group*3)
 scaled=math.floor(scaled*10+0.5)/10
 if scaled>=1000 then scaled=1;group+=1 end
 if group>=#suffixes then return sign..string.format("%.2e",value) end
 local text=if scaled%1==0 then string.format("%.0f",scaled) else string.format("%.1f",scaled)
 return sign..text..suffixes[group+1]
end
return table.freeze(Format)
