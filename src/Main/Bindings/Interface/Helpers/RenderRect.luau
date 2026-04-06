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

function RenderRect.fromViewportCenter(size: Vector2)
	local viewportSize = (workspace.CurrentCamera :: Camera).ViewportSize
	local absPosition = (viewportSize - size) / 2
	return RenderRect.fromAbs(absPosition, size)
end

function RenderRect.fromGuiObject(subject: GuiObject)
	local absPosition = subject.AbsolutePosition
	local absSize = subject.AbsoluteSize
	return RenderRect.fromAbs(absPosition, absSize)
end

return RenderRect
