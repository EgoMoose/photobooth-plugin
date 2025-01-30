--!strict

-- this module handles calculating rects as they would be rendered on a screen.
-- since there's no such thing as half a pixel, what's actually rendered
-- can change by a pixel or two.

local RenderRect = {}

function RenderRect.fromAbs(position: Vector2, size: Vector2)
	local minX = math.round(position.X)
	local minY = math.round(position.Y)

	local maxX = math.round(position.X + size.X)
	local maxY = math.round(position.Y + size.Y)

	return Rect.new(minX, minY, maxX, maxY)
end

function RenderRect.fromRect(rect: Rect)
	return RenderRect.fromAbs(rect.Min, rect.Max - rect.Min)
end

return RenderRect
