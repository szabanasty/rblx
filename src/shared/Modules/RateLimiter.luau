--!strict
local RateLimiter = {}
RateLimiter.__index = RateLimiter
type Bucket = {Tokens: number, Updated: number}
export type Limiter = typeof(setmetatable({Capacity = 1, Refill = 1, Buckets = {} :: {[number]: Bucket}}, RateLimiter))
function RateLimiter.new(capacity: number, refill: number): Limiter
    assert(capacity == capacity and capacity > 0 and capacity < math.huge and refill == refill and refill > 0 and refill < math.huge)
    return setmetatable({Capacity = capacity, Refill = refill, Buckets = {}}, RateLimiter) :: Limiter
end
function RateLimiter.Allow(self: Limiter, key: number, now: number, cost: number?): boolean
    local needed = cost or 1
    if now ~= now or math.abs(now) == math.huge or needed ~= needed or needed <= 0 or needed > self.Capacity then return false end
    local bucket = self.Buckets[key]
    if not bucket then
        bucket = {Tokens = self.Capacity, Updated = now}
        self.Buckets[key] = bucket
    end
    bucket.Tokens = math.min(self.Capacity, bucket.Tokens + math.max(0, now - bucket.Updated) * self.Refill)
    bucket.Updated = math.max(now, bucket.Updated)
    if bucket.Tokens < needed then return false end
    bucket.Tokens -= needed
    return true
end
function RateLimiter.Remove(self: Limiter, key: number)
    self.Buckets[key] = nil
end
return RateLimiter
