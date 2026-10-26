--!strict
local Protocol = {}
-- Clients send intents only. Amounts, positions, identity and timing are server-owned.
Protocol.Remotes = table.freeze({ GetSnapshot = "RemoteFunction", SnapshotChanged = "RemoteEvent", Action = "RemoteEvent", ActionResult = "RemoteEvent", Feedback = "RemoteEvent" })
function Protocol.validRequest(payload: any): boolean
 if type(payload) ~= "table" or payload.Version ~= 1 then return false end
 local count = 0
 for _ in pairs(payload) do
  count += 1
  if count > 1 then return false end
 end
 return count == 1
end
local function integer(value:any,max:number):boolean
 return type(value)=="number" and value%1==0 and value>=1 and value<=max
end
function Protocol.validAction(payload:any):boolean
 if type(payload)~="table" or payload.Version~=1 then return false end
 local specifications:any={Select={TreadmillId=5},BuyVehicle={VehicleId=10},EquipVehicle={VehicleId=10},Hatch={EggId=3},EquipPet={PetId=true},UnequipPet={PetId=true},EquipBest={},UnequipAll={}}
 local spec=specifications[payload.Action]
 local economic=payload.Action=="BuyVehicle" or payload.Action=="EquipVehicle" or payload.Action=="Hatch" or payload.Action=="EquipPet" or payload.Action=="UnequipPet" or payload.Action=="EquipBest" or payload.Action=="UnequipAll"
 local allowed:any={Version=true,Action=true}
 if spec then for key,max in pairs(spec) do
  allowed[key]=true
  if max==true then if type(payload[key])~="string" or #payload[key]<1 or #payload[key]>64 then return false end
  elseif not integer(payload[key],max :: number) then return false end
 end end
 if economic then allowed.RequestId=true;if not integer(payload.RequestId,9007199254740991) then return false end end
 if payload.Action=="StartRace" then allowed.Difficulty=true;if payload.Difficulty~=nil and payload.Difficulty~="Easy" and payload.Difficulty~="Medium" and payload.Difficulty~="Hard" then return false end end
 if not spec and payload.Action~="Click" and payload.Action~="Stop" and payload.Action~="Rebirth" and payload.Action~="StartRace" and payload.Action~="AbortRace" then return false end
 local count=0
 for key in pairs(payload) do count+=1;if count>4 or not allowed[key] then return false end end
 return true
end
function Protocol.validSnapshot(payload: any): boolean
 if type(payload) ~= "table" then return false end
 for _, key in ipairs({ "Energy", "Cash", "Rebirths" }) do
  local value = payload[key]
  if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then return false end
 end
 return true
end
return table.freeze(Protocol)
