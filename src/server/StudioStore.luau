--!strict
-- Explicit Studio preview only. Never a fallback for a failed live DataStore.
local Store={}
function Store.new():any
 local records:any={}
 local function copy(value:any):any
  if type(value)~="table" then return value end
  local result:any={};for key,child in pairs(value) do result[key]=copy(child) end;return result
 end
 return {UpdateAsync=function(_:any,key:string,transform:(any)->any):any
  local nextValue=transform(copy(records[key]))
  if nextValue~=nil then records[key]=copy(nextValue) end
  return copy(nextValue)
 end}
end
return Store
