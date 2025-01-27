--!strict

local RectHelper = {}

function RectHelper.fromAbs(position: Vector2, size: Vector2)
	local px = math.round(position.X)
	local py = math.round(position.Y)

	local sx = math.ceil(math.floor(position.X) + size.X - px)
	local sy = math.ceil(math.floor(position.Y) + size.Y - py)

	return Rect.new(px, py, px + sx, py + sy)
end

return RectHelper
