local PathSpline = {}
PathSpline.__index = PathSpline

local TURN_RADIUS = 6

-- Math helper formulas
local function getQuadraticBezierPoint(t, p0, p1, p2)
	local l1 = p0:Lerp(p1, t)
	local l2 = p1:Lerp(p2, t)
	return l1:Lerp(l2, t)
end

function PathSpline.new(waypointFolder)
	local self = setmetatable({}, PathSpline)

	-- 1. Sort raw parts numerically
	local parts = waypointFolder:GetChildren()
	table.sort(parts, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)

	local rawPoints = {}
	for _, p in ipairs(parts) do
		table.insert(rawPoints, p.Position)
	end
	
	-- 2. Analyze waypoints and group them into distinct geometric sections
	-- Sections can either be a "Straight" line or a "Curve" corner
	local sections = {}
	
	local lastEnd = rawPoints[1]
	
	for i = 2, #rawPoints - 1 do
		local p0 = rawPoints[i - 1]
		local p1 = rawPoints[i] -- The corner
		local p2 = rawPoints[i + 1]

		local dir1 = (p1 - p0).Unit
		local dir2 = (p2 - p1).Unit

		local isStraight = dir1:Dot(dir2) > 0.999

		if not isStraight then
			local startCurve = p1 - (dir1 * math.min(TURN_RADIUS, (p1 - p0).Magnitude * 0.4))
			local endCurve = p1 + (dir2 * math.min(TURN_RADIUS, (p2 - p1).Magnitude * 0.4))
			
			-- Add the straight line leading UP to the turn
			table.insert(sections, {Type = "Straight", P0 = lastEnd, P1 = startCurve})
			-- Add the perfect mathematical curve zone
			table.insert(sections, {Type = "Curve", P0 = startCurve, P1 = p1, P2 = endCurve})
			
			lastEnd = endCurve
		end
	end
	
	-- Add the final straight line leading to the end base
	table.insert(sections, {Type = "Straight", P0 = lastEnd, P1 = rawPoints[#rawPoints]})
	
	self.Sections = sections
	self.NumSections = #sections

	self:BakeDistanceLUT()

	return self
end

-- Evaluates the raw path using dynamic mathematical equations instead of segment lists
function PathSpline:_GetRawPosition(t)
	t = math.clamp(t, 0, 1)
	if t >= 1 then
		local lastSec = self.Sections[self.NumSections]
		return lastSec.Type == "Straight" and lastSec.P1 or lastSec.P2
	end

	local scaledT = t * self.NumSections
	local index = math.floor(scaledT) + 1
	local localT = scaledT - math.floor(scaledT)

	local sec = self.Sections[index]
	
	if sec.Type == "Straight" then
		-- Perfect linear line interpolation
		return sec.P0:Lerp(sec.P1, localT)
	else
		-- Pure mathematical quadratic bezier curve evaluation
		return getQuadraticBezierPoint(localT, sec.P0, sec.P1, sec.P2)
	end
end

function PathSpline:BakeDistanceLUT()
	local lut = {}
	local totalLength = 0
	local samples = 600 -- Increased resolution slightly for perfect precision mapping

	local prevPos = self:_GetRawPosition(0)
	table.insert(lut, { Length = 0, RawT = 0 })

	for i = 1, samples do
		local rawT = i / samples
		local currentPos = self:_GetRawPosition(rawT)

		totalLength = totalLength + (currentPos - prevPos).Magnitude
		table.insert(lut, { Length = totalLength, RawT = rawT })

		prevPos = currentPos
	end

	self.DistanceLUT = lut
	self.TotalLength = totalLength
end

function PathSpline:CalculateTotalLength()
	return self.TotalLength
end

function PathSpline:GetPosition(t)
	t = math.clamp(t, 0, 1)
	local targetLength = t * self.TotalLength
	
	local lut = self.DistanceLUT
	local low = 1
	local high = #lut
	
	while low < high - 1 do
		local mid = math.floor((low + high) / 2)
		if lut[mid].Length < targetLength then
			low = mid
		else
			high = mid
		end
	end
	
	local sampleA = lut[low]
	local sampleB = lut[high]
	
	local lengthDiff = sampleB.Length - sampleA.Length
	local localRatio = 0
	if lengthDiff > 0 then
		localRatio = (targetLength - sampleA.Length) / lengthDiff
	end
	
	local correctRawT = sampleA.RawT + (localRatio * (sampleB.RawT - sampleA.RawT))
	return self:_GetRawPosition(correctRawT)
end

return PathSpline
