--!strict
local Protocol = {}
-- Clients may only request their own read-only HUD snapshot. No client currency writes.
Protocol.Remotes = table.freeze({ GetSnapshot = "RemoteFunction", SnapshotChanged = "RemoteEvent" })
function Protocol.validRequest(payload: any): boolean
 if type(payload) ~= "table" or payload.Version ~= 1 then return false end
 local count = 0
 for _ in pairs(payload) do
  count += 1
  if count > 1 then return false end
 end
 return count == 1
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
