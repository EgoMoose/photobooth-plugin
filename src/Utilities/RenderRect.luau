--!strict

-- this module handles calculating rects as they would be rendered on a screen.
-- since there's no such thing as half a pixel, what's actually rendered
-- can change by a pixel or two.

local RenderRect = {}

function RenderRect.fromAbs(position: Vector2, size: Vector2)
	local px = math.round(position.X)
	local py = math.round(position.Y)

	local sx = math.ceil(math.floor(position.X) + size.X - px)
	local sy = math.ceil(math.floor(position.Y) + size.Y - py)

	return Rect.new(px, py, px + sx, py + sy)
end

function RenderRect.fromRect(rect: Rect)
	return RenderRect.fromAbs(rect.Min, rect.Max - rect.Min)
end

return RenderRect
