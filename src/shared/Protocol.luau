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
function Protocol.validAction(payload: any): boolean
 if type(payload) ~= "table" or payload.Version ~= 1 then return false end
 local count = 0
 for key in pairs(payload) do
  count += 1
  if count > 3 or (key ~= "Version" and key ~= "Action" and key ~= "TreadmillId") then return false end
 end
 if payload.Action == "Select" then
  return count == 3 and type(payload.TreadmillId) == "number" and payload.TreadmillId % 1 == 0 and payload.TreadmillId >= 1 and payload.TreadmillId <= 5
 end
 return count == 2 and (payload.Action == "Click" or payload.Action == "Stop" or payload.Action == "Rebirth" or payload.Action == "StartRace" or payload.Action == "AbortRace")
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
