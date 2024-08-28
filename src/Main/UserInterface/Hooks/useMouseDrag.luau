--!strict

--[[
From srcfenner's StudioComponents:
https://github.com/sircfenner/StudioComponents

The MIT License (MIT)

Copyright (c) 2024 sircfenner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

type Callback<Args..., Rets...> = (Args...) -> Rets...

local function useFreshCallback<Args..., Rets...>(callback: Callback<Args..., Rets...>, deps: { any }?): Callback<Args..., Rets...>
	local ref = React.useRef(callback) :: { current: Callback<Args..., Rets...> }

	React.useEffect(function()
		ref.current = callback
	end, deps)

	return function(...)
		return ref.current(...)
	end
end

local function useMouseDrag(
	callback: (rbx: GuiObject, input: InputObject) -> (),
	deps: { any }?,
	onBeganCallback: ((rbx: GuiObject, input: InputObject) -> ())?, -- NB: consumer needs to guard against stale state
	onEndedCallback: (() -> ())?
)
	local freshCallback = useFreshCallback(callback, deps)

	-- we use a state so consumers can re-render
	-- ... as well as a ref so we have an immediately-updated/available value
	local holdingState, setHoldingState = React.useState(false)
	local holding = React.useRef(false)

	local lastRbx = React.useRef(nil :: GuiObject?)
	local moveInput = React.useRef(nil :: InputObject?)
	local moveConnection = React.useRef(nil :: RBXScriptConnection?)

	local function runCallback(input: InputObject)
		freshCallback(lastRbx.current :: GuiObject, input)
	end

	local function connect()
		if moveConnection.current then
			moveConnection.current:Disconnect()
		end
		local input = moveInput.current :: InputObject
		local signal = input:GetPropertyChangedSignal("Position")
		moveConnection.current = signal:Connect(function()
			runCallback(input)
		end)
		runCallback(input)
	end

	local function disconnect()
		if moveConnection.current then
			moveConnection.current:Disconnect()
			moveConnection.current = nil
		end
		if onEndedCallback and holding.current == true then
			onEndedCallback()
		end
	end

	-- React.useEffect(function()
	-- 	if moveInput.current then
	-- 		runCallback(moveInput.current)
	-- 	end
	-- end, deps)

	React.useEffect(function()
		return disconnect
	end, {})

	local function onInputBegan(rbx: GuiObject, input: InputObject)
		lastRbx.current = rbx
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			moveInput.current = input
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			holding.current = true
			setHoldingState(true)
			if onBeganCallback then
				onBeganCallback(rbx, input)
			end
			if moveInput.current then
				connect()
			else
				-- case: clicked without move input first
				-- this can happen if the instance moves to be under the mouse
				runCallback(input)
			end
		end
	end

	local function onInputChanged(rbx: GuiObject, input: InputObject)
		lastRbx.current = rbx
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			moveInput.current = input
			if holding.current and not moveConnection.current then
				-- handles the case above and connects listener on first move
				connect()
			end
		end
	end

	local function onInputEnded(rbx: GuiObject, input: InputObject)
		lastRbx.current = rbx
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			disconnect()
			holding.current = false
			setHoldingState(false)
		end
	end

	local function isActive()
		return holdingState == true
	end

	local function cancel()
		disconnect()
		holding.current = false
		moveInput.current = nil
		setHoldingState(false)
	end

	return {
		isActive = isActive,
		cancel = cancel,
		onInputBegan = onInputBegan,
		onInputChanged = onInputChanged,
		onInputEnded = onInputEnded,
	}
end

return useMouseDrag
