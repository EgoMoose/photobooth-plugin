--!strict

--[[
MIT License

Copyright 2011 Jon Leighton
https://gist.github.com/jonleighton/958841

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

local BASE64_ENCODING = ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"):split("")

local base64IndexLookup = {}
for i, char in BASE64_ENCODING do
	base64IndexLookup[char] = i
end

local function encode(b: buffer)
	local base64 = ""
	local len = buffer.len(b)

	for i = 0, len - 1, 3 do
		local b0 = if i + 0 < len then buffer.readu8(b, i + 0) else 0
		local b1 = if i + 1 < len then buffer.readu8(b, i + 1) else 0
		local b2 = if i + 2 < len then buffer.readu8(b, i + 2) else 0

		base64 ..= BASE64_ENCODING[1 + bit32.rshift(b0, 2)]
		base64 ..= BASE64_ENCODING[1 + bit32.bor(bit32.lshift(bit32.band(b0, 3), 4), bit32.rshift(b1, 4))]
		base64 ..= BASE64_ENCODING[1 + bit32.bor(bit32.lshift(bit32.band(b1, 15), 2), bit32.rshift(b2, 6))]
		base64 ..= BASE64_ENCODING[1 + bit32.band(b2, 63)]
	end

	if len % 3 == 2 then
		base64 = base64:sub(1, -2) .. "="
	elseif len % 3 == 1 then
		base64 = base64:sub(1, -3) .. "=="
	end

	return base64
end

local function decode(base64: string)
	local matches = base64:match("=+$") or ""
	local b = buffer.create((#base64 * 0.75) - #matches)

	local p = 0
	local function writeu8(u8: number)
		buffer.writeu8(b, p, u8)
		p = p + 1
	end

	for i = 0, buffer.len(b) - 1, 4 do
		local e1 = (base64IndexLookup[base64:sub(i + 1, i + 1)] or 1) - 1
		local e2 = (base64IndexLookup[base64:sub(i + 2, i + 2)] or 1) - 1
		local e3 = (base64IndexLookup[base64:sub(i + 3, i + 3)] or 1) - 1
		local e4 = (base64IndexLookup[base64:sub(i + 4, i + 4)] or 1) - 1

		writeu8(bit32.bor(bit32.lshift(e1, 2), bit32.rshift(e2, 4)))
		writeu8(bit32.bor(bit32.lshift(bit32.band(e2, 15), 4), bit32.rshift(e3, 2)))
		writeu8(bit32.bor(bit32.lshift(bit32.band(e3, 3), 6), bit32.rshift(e4, 64)))
	end

	return b
end

return {
	encode = encode,
	decode = decode,
}
