--!strict
local State={}
function State.new(phone: boolean): any
 return {Collapsed=phone,Animations=true,Popups=true,Sound=true,Volume=0.35,LastEvent=0,Active="Energy"}
end
function State.setting(state: any, name: string, value: any): boolean
 if name=="Volume" then
  if type(value)~="number" or value~=value then return false end
  state.Volume=math.clamp(value,0,1);return true
 end
 if name~="Collapsed" and name~="Animations" and name~="Popups" and name~="Sound" then return false end
 if type(value)~="boolean" then return false end
 state[name]=value;return true
end
function State.event(state: any, id: number): boolean
 if id%1~=0 or id<=state.LastEvent then return false end
 state.LastEvent=id;return true
end
return table.freeze(State)
