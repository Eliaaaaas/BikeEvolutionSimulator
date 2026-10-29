--!strict
local Limiter: any = {}
Limiter.__index = Limiter
function Limiter.new(capacity: number, refill: number, clock: () -> number): any
 return setmetatable({Capacity=capacity, Refill=refill, Clock=clock, Buckets={}}, Limiter)
end
function Limiter.allow(self: any, key: any): boolean
 local now = self.Clock()
 local bucket = self.Buckets[key] or {Tokens=self.Capacity, At=now}
 self.Buckets[key] = bucket
 bucket.Tokens = math.min(self.Capacity, bucket.Tokens + math.max(0, now-bucket.At)*self.Refill)
 bucket.At = now
 if bucket.Tokens < 1 then return false end
 bucket.Tokens -= 1
 return true
end
function Limiter.remove(self: any, key: any) self.Buckets[key] = nil end
return Limiter
