--!strict
-- Injected clocks make disconnect/shutdown recovery testable without Roblox.
local SavePolicy = {}
function SavePolicy.flush(session: any, key: string, release: boolean, deadline: number,
 clock: () -> number, pause: () -> (), log: (any) -> ()): (boolean, string?)
 repeat
  if clock() >= math.min(deadline, session.Expires) then return false, "DeadlineExceeded" end
  local ok, reason, expires = session.Backend:save(key, session.Data, release)
  if ok then
   session.Expires = expires
   return true, nil
  end
  log({ Event = "ProfileSaveFailed", Key = key, Reason = reason, Release = release, LeaseExpires = session.Expires })
  if reason ~= "DataStoreUnavailable" or not release then return false, reason end
  pause()
 until clock() >= math.min(deadline, session.Expires)
 return false, "DeadlineExceeded"
end
return table.freeze(SavePolicy)
