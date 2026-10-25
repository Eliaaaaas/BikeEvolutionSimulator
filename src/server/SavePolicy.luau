--!strict
-- Injected clocks make disconnect/shutdown recovery testable without Roblox.
local SavePolicy = {}
function SavePolicy.flush(session: any, key: string, release: boolean, deadline: number | (() -> number),
 clock: () -> number, pause: () -> (), log: (any) -> ()): (boolean, string?)
 local function cutoff(): number
  local current = if type(deadline) == "function" then deadline() else deadline
  return math.min(current, session.Expires)
 end
 repeat
  if clock() >= cutoff() then return false, "DeadlineExceeded" end
  local ok, reason, expires = session.Backend:save(key, session.Data, release)
  if ok then
   session.Expires = expires
   return true, nil
  end
  log({ Event = "ProfileSaveFailed", Key = key, Reason = reason, Release = release, LeaseExpires = session.Expires })
  if reason ~= "DataStoreUnavailable" or not release then return false, reason end
  pause()
 until clock() >= cutoff()
 return false, "DeadlineExceeded"
end
return table.freeze(SavePolicy)
