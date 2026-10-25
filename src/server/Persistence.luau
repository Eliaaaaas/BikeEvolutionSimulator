--!strict
-- Pure adapter: store, clock, retry wait and session id are injected for deterministic tests.
local Persistence: any = {}
Persistence.__index = Persistence
function Persistence.new(store: any, profile: any, settings: any, sessionId: string, clock: () -> number, waitRetry: (number) -> (), log: ((any) -> ())?): any
 return setmetatable({ store = store, profile = profile, settings = settings,
  sessionId = sessionId, clock = clock, waitRetry = waitRetry, log = log or function() end, sequence = 0 }, Persistence)
end
function Persistence.update(self: any, key: string, transform: (any) -> any): (boolean, any)
 local lastError
 for attempt = 1, self.settings.Attempts do
  local ok, result = pcall(function() return self.store:UpdateAsync(key, transform) end)
  if ok then return true, result end
  lastError = result
  self.log({ Event = "DataStoreRetry", Key = key, Attempt = attempt, Attempts = self.settings.Attempts, Error = tostring(result) })
  if attempt < self.settings.Attempts then self.waitRetry(attempt) end
 end
 return false, tostring(lastError)
end
function Persistence.load(self: any, key: string): (any, string?, number?)
 local ok, record = self:update(key, function(old: any): any
  if old == nil then old = { Data = self.profile.new() } end
  -- Reject corrupt/future schemas; never silently replace existing data with defaults.
  if type(old) ~= "table" or not self.profile.validate(old.Data) then return nil end
  if old.Lock ~= nil then
   if type(old.Lock) ~= "table" or type(old.Lock.Id) ~= "string" or type(old.Lock.Expires) ~= "number"
    or old.Lock.Expires ~= old.Lock.Expires or old.Lock.Expires == math.huge or old.Lock.Expires < 0 then return nil end
   if old.Lock.Id ~= self.sessionId and old.Lock.Expires > self.clock() then return nil end
  end
  return { Data = self.profile.copy(old.Data), Lock = { Id = self.sessionId, Expires = self.clock() + self.settings.LeaseSeconds } }
 end)
 if not ok then return nil, "DataStoreUnavailable" end
 if type(record) ~= "table" or not record.Lock or record.Lock.Id ~= self.sessionId then return nil, "LockedOrInvalidProfile" end
 return self.profile.copy(record.Data), nil, record.Lock.Expires
end
function Persistence.save(self: any, key: string, data: any, release: boolean): (boolean, string?, number?)
 if not self.profile.validate(data) then return false, "InvalidProfile", nil end
 self.sequence += 1
 local writeId = self.sessionId .. ":" .. tostring(self.sequence)
 local snapshot = self.profile.copy(data)
 local ok, result = self:update(key, function(old: any): any
  -- A committed release whose response was lost is safe to acknowledge again.
  if release and type(old) == "table" and old.WriteId == writeId and old.Lock == nil then return old end
  if type(old) ~= "table" or type(old.Lock) ~= "table" or old.Lock.Id ~= self.sessionId
   or old.Lock.Expires <= self.clock() then return nil end
  return { Data = snapshot, WriteId = writeId, Lock = if release then nil else { Id = self.sessionId, Expires = self.clock() + self.settings.LeaseSeconds } }
 end)
 if not ok then return false, "DataStoreUnavailable", nil end
 if result == nil then return false, "SessionLost", nil end
 return true, nil, if release then 0 else result.Lock.Expires
end
return Persistence
