local PathSpline = {}
PathSpline.__index = PathSpline

local TURN_RADIUS = 6

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

	local bakedPoints = {}
	table.insert(bakedPoints, rawPoints[1])

	for i = 2, #rawPoints - 1 do
		local p0 = rawPoints[i - 1]
		local p1 = rawPoints[i]
		local p2 = rawPoints[i + 1]

		local dir1 = (p1 - p0).Unit
		local dir2 = (p2 - p1).Unit

		local isStraight = dir1:Dot(dir2) > 0.999

		if isStraight then
			table.insert(bakedPoints, p1)
		else
			local startCurve = p1 - (dir1 * math.min(TURN_RADIUS, (p1 - p0).Magnitude * 0.4))
			local endCurve = p1 + (dir2 * math.min(TURN_RADIUS, (p2 - p1).Magnitude * 0.4))

			local cornerSegments = 12
			for step = 0, cornerSegments do
				local t = step / cornerSegments
				table.insert(bakedPoints, getQuadraticBezierPoint(t, startCurve, p1, endCurve))
			end
		end
	end
	table.insert(bakedPoints, rawPoints[#rawPoints])

	self.Points = bakedPoints
	self.NumPoints = #bakedPoints

	self:BakeDistanceLUT()

	return self
end

function PathSpline:_GetRawPosition(t)
	t = math.clamp(t, 0, 1)
	if t >= 1 then
		return self.Points[self.NumPoints]
	end

	local scaledT = t * (self.NumPoints - 1)
	local index = math.floor(scaledT) + 1
	local localT = scaledT - math.floor(scaledT)

	local pA = self.Points[index]
	local pB = self.Points[math.min(self.NumPoints, index + 1)]

	return pA:Lerp(pB, localT)
end

function PathSpline:BakeDistanceLUT()
	local lut = {}
	local totalLength = 0
	local samples = 400

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
