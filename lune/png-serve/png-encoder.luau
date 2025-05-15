--!strict
--cspell:disable

--[[
http://www.chrfr.de/software/midp_png.html
https://github.com/ggcrunchy/image_ops/blob/master/png_encode.lua

PNG encoder (C) 2006-2009 by Christian Fröschlin, www.chrfr.de

MIT License

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

local BLOCK_SIZE = 32000
local BYTES = string.char(8, (31 - (8 * 256) % 31) % 31)

local function u32(num: number)
	local low1, low2, low3 = num % 2 ^ 8, num % 2 ^ 16, num % 2 ^ 24
	return string.char((num - low3) / 2 ^ 24, (low3 - low2) / 2 ^ 16, (low2 - low1) / 2 ^ 8, low1)
end

local function calcADLER32(data: { number })
	local s1, s2 = 1, 0
	for i = 1, #data do
		local abs = data[i] >= 0 and data[i] or data[i] + 256
		s1 = (s1 + abs) % 65521
		s2 = (s2 + s1) % 65521
	end
	return s2 * 2 ^ 16 + s1
end

local function writeUncompressedBlock(
	stream: { string },
	isLast: boolean,
	data: { number },
	offset: number,
	len: number
)
	local nlen = bit32.band(bit32.bnot(len), 0xFFFF)
	local lenFF, nlenFF = bit32.band(len, 0xFF), bit32.band(nlen, 0xFF)

	stream[#stream + 1] = string.char(isLast and 1 or 0)
	stream[#stream + 1] = string.char(lenFF)
	stream[#stream + 1] = string.char(bit32.rshift(len - lenFF, 8))
	stream[#stream + 1] = string.char(nlenFF)
	stream[#stream + 1] = string.char(bit32.rshift(nlen - nlenFF, 8))

	for i = 1, len, 512 do
		stream[#stream + 1] = string.char(unpack(data, offset + i, offset + math.min(i + 511, len)))
	end
end

local function uncompressedWrite(data: { number })
	local subs, pos, n = { BYTES }, 0, #data

	repeat
		local left = n - pos
		local isLast = left <= BLOCK_SIZE
		writeUncompressedBlock(subs, isLast, data, pos, isLast and left or BLOCK_SIZE)
		pos = pos + BLOCK_SIZE
	until isLast

	subs[#subs + 1] = u32(calcADLER32(data))

	return table.concat(subs, "")
end

local crcLUT: { number }
local function updateCRC(crc: number, bytes: string)
	if not crcLUT then
		local lut = table.create(256, 0)
		for i = 0, 255 do
			local c = i
			for _ = 1, 8 do
				local bit = bit32.band(c, 0x1)
				c = 0.5 * (c - bit)
				if bit ~= 0 then
					c = bit32.bxor(c, 0xEDB88320)
				end
			end
			lut[i + 1] = c
		end
		crcLUT = lut
	end

	for b in string.gmatch(bytes, ".") do
		crc = bit32.bxor(crcLUT[bit32.band(bit32.bxor(crc, string.byte(b)), 0xFF) + 1], bit32.rshift(crc, 8))
	end
	return crc
end

local function toChunk(stream: { string }, id: string, bytes: string)
	stream[#stream + 1] = u32(#bytes)
	stream[#stream + 1] = id
	stream[#stream + 1] = bytes

	local crc = 0xFFFFFFFF
	crc = updateCRC(crc, id)
	crc = updateCRC(crc, bytes)

	stream[#stream + 1] = u32(bit32.bnot(crc))
end

local function encode(width: number, height: number, rgba: { number })
	local data = {}
	local i, j = 1, 1

	for _ = 1, height do
		data[i] = 0
		i = i + 1

		for _ = 1, width * 4 do
			data[i] = rgba[j]
			i = i + 1
			j = j + 1
		end
	end

	local stream = { "\137\080\078\071\013\010\026\010" }

	toChunk(stream, "IHDR", u32(width) .. u32(height) .. string.char(8, 6, 0, 0, 0))
	toChunk(stream, "IDAT", uncompressedWrite(data))
	toChunk(stream, "IEND", "")

	return table.concat(stream, "")
end

return encode
