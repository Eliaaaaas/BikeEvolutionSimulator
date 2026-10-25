--!strict
local Numbers = {}
Numbers.Max = 1e300
function Numbers.valid(value: number): boolean
 return value == value and value >= 0 and value <= Numbers.Max
end
function Numbers.multiply(a: number, b: number): number
 assert(Numbers.valid(a) and Numbers.valid(b), "Invalid numeric operand")
 if a == 0 or b == 0 then return 0 end
 return if a > Numbers.Max / b then Numbers.Max else math.min(a * b, Numbers.Max)
end
function Numbers.add(a: number, b: number): number
 assert(Numbers.valid(a) and Numbers.valid(b), "Invalid numeric operand")
 return if a > Numbers.Max - b then Numbers.Max else math.min(a + b, Numbers.Max)
end
function Numbers.power(base: number, exponent: number): number
 assert(Numbers.valid(base) and exponent >= 0 and exponent % 1 == 0 and exponent <= 1024, "Invalid power")
 local result = 1
 for _ = 1, exponent do result = Numbers.multiply(result, base) end
 return result
end
return table.freeze(Numbers)
