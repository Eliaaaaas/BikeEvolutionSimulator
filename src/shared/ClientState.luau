--!strict
local State={}
local Numbers=require(script.Parent.Numbers)
function State.new(phone: boolean): any
 return {Collapsed=phone,Animations=true,Popups=true,Sound=true,Volume=0.35,LastEvent=0,Active="Energy"}
end
function State.setting(state: any, name: string, value: any): boolean
 if name=="Volume" then
  if type(value)~="number" or value~=value or math.abs(value)==math.huge then return false end
  state.Volume=math.clamp(value,0,1);return true
 end
 if name~="Collapsed" and name~="Animations" and name~="Popups" and name~="Sound" then return false end
 if type(value)~="boolean" then return false end
 state[name]=value;return true
end
function State.event(state: any, id: number): boolean
 if type(id)~="number" or not Numbers.validRebirth(id) or id<=state.LastEvent then return false end
 state.LastEvent=id;return true
end
-- RemoteFunction responses can arrive after newer SnapshotChanged events.
-- Never roll back a revision, and never attach older inventory to a newer revision.
function State.snapshot(previous:any,incoming:any):any
 if type(incoming)~="table" or type(incoming.Revision)~="number" or not Numbers.validRebirth(incoming.Revision) then return nil end
 if previous and incoming.Revision<previous.Revision then return nil end
 if incoming.SnapshotId~=nil then
  if type(incoming.SnapshotId)~="number" or not Numbers.validRebirth(incoming.SnapshotId) then return nil end
  if previous and previous.SnapshotId and incoming.SnapshotId<=previous.SnapshotId then return nil end
 end
 local merged=table.clone(incoming)
 for _,key in ipairs({"Pets","EquippedPets","DiscoveredPets","OwnedVehicles"}) do
  if merged[key]==nil then
   if not previous or previous.InventoryRevision~=incoming.InventoryRevision then return nil end
   merged[key]=previous[key]
   if merged[key]==nil then return nil end
  end
 end
 return merged
end
return table.freeze(State)
