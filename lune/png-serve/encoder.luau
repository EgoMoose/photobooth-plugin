--!nocheck

--[[
                   GNU LESSER GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.


  This version of the GNU Lesser General Public License incorporates
the terms and conditions of version 3 of the GNU General Public
License, supplemented by the additional permissions listed below.

  0. Additional Definitions.

  As used herein, "this License" refers to version 3 of the GNU Lesser
General Public License, and the "GNU GPL" refers to version 3 of the GNU
General Public License.

  "The Library" refers to a covered work governed by this License,
other than an Application or a Combined Work as defined below.

  An "Application" is any work that makes use of an interface provided
by the Library, but which is not otherwise based on the Library.
Defining a subclass of a class defined by the Library is deemed a mode
of using an interface provided by the Library.

  A "Combined Work" is a work produced by combining or linking an
Application with the Library.  The particular version of the Library
with which the Combined Work was made is also called the "Linked
Version".

  The "Minimal Corresponding Source" for a Combined Work means the
Corresponding Source for the Combined Work, excluding any source code
for portions of the Combined Work that, considered in isolation, are
based on the Application, and not on the Linked Version.

  The "Corresponding Application Code" for a Combined Work means the
object code and/or source code for the Application, including any data
and utility programs needed for reproducing the Combined Work from the
Application, but excluding the System Libraries of the Combined Work.

  1. Exception to Section 3 of the GNU GPL.

  You may convey a covered work under sections 3 and 4 of this License
without being bound by section 3 of the GNU GPL.

  2. Conveying Modified Versions.

  If you modify a copy of the Library, and, in your modifications, a
facility refers to a function or data to be supplied by an Application
that uses the facility (other than as an argument passed when the
facility is invoked), then you may convey a copy of the modified
version:

   a) under this License, provided that you make a good faith effort to
   ensure that, in the event an Application does not supply the
   function or data, the facility still operates, and performs
   whatever part of its purpose remains meaningful, or

   b) under the GNU GPL, with none of the additional permissions of
   this License applicable to that copy.

  3. Object Code Incorporating Material from Library Header Files.

  The object code form of an Application may incorporate material from
a header file that is part of the Library.  You may convey such object
code under terms of your choice, provided that, if the incorporated
material is not limited to numerical parameters, data structure
layouts and accessors, or small macros, inline functions and templates
(ten or fewer lines in length), you do both of the following:

   a) Give prominent notice with each copy of the object code that the
   Library is used in it and that the Library and its use are
   covered by this License.

   b) Accompany the object code with a copy of the GNU GPL and this license
   document.

  4. Combined Works.

  You may convey a Combined Work under terms of your choice that,
taken together, effectively do not restrict modification of the
portions of the Library contained in the Combined Work and reverse
engineering for debugging such modifications, if you also do each of
the following:

   a) Give prominent notice with each copy of the Combined Work that
   the Library is used in it and that the Library and its use are
   covered by this License.

   b) Accompany the Combined Work with a copy of the GNU GPL and this license
   document.

   c) For a Combined Work that displays copyright notices during
   execution, include the copyright notice for the Library among
   these notices, as well as a reference directing the user to the
   copies of the GNU GPL and this license document.

   d) Do one of the following:

       0) Convey the Minimal Corresponding Source under the terms of this
       License, and the Corresponding Application Code in a form
       suitable for, and under terms that permit, the user to
       recombine or relink the Application with a modified version of
       the Linked Version to produce a modified Combined Work, in the
       manner specified by section 6 of the GNU GPL for conveying
       Corresponding Source.

       1) Use a suitable shared library mechanism for linking with the
       Library.  A suitable mechanism is one that (a) uses at run time
       a copy of the Library already present on the user's computer
       system, and (b) will operate properly with a modified version
       of the Library that is interface-compatible with the Linked
       Version.

   e) Provide Installation Information, but only if you would otherwise
   be required to provide such information under section 6 of the
   GNU GPL, and only to the extent that such information is
   necessary to install and execute a modified version of the
   Combined Work produced by recombining or relinking the
   Application with a modified version of the Linked Version. (If
   you use option 4d0, the Installation Information must accompany
   the Minimal Corresponding Source and Corresponding Application
   Code. If you use option 4d1, you must provide the Installation
   Information in the manner specified by section 6 of the GNU GPL
   for conveying Corresponding Source.)

  5. Combined Libraries.

  You may place library facilities that are a work based on the
Library side by side in a single library together with other library
facilities that are not Applications and are not covered by this
License, and convey such a combined library under terms of your
choice, if you do both of the following:

   a) Accompany the combined library with a copy of the same work based
   on the Library, uncombined with any other library facilities,
   conveyed under the terms of this License.

   b) Give prominent notice with the combined library that part of it
   is a work based on the Library, and explaining where to find the
   accompanying uncombined form of the same work.

  6. Revised Versions of the GNU Lesser General Public License.

  The Free Software Foundation may publish revised and/or new versions
of the GNU Lesser General Public License from time to time. Such new
versions will be similar in spirit to the present version, but may
differ in detail to address new problems or concerns.

  Each version is given a distinguishing version number. If the
Library as you received it specifies that a certain numbered version
of the GNU Lesser General Public License "or any later version"
applies to it, you have the option of following the terms and
conditions either of that published version or of any later version
published by the Free Software Foundation. If the Library as you
received it does not specify a version number of the GNU Lesser
General Public License, you may choose any version of the GNU Lesser
General Public License ever published by the Free Software Foundation.

  If the Library as you received it specifies that a proxy can decide
whether future versions of the GNU Lesser General Public License shall
apply, that proxy's public statement of acceptance of any version is
permanent authorization for you to choose that version for the
Library.
--]]

local Png = {}
Png.__index = Png

local DEFLATE_MAX_BLOCK_SIZE = 65535

local bit = bit32

local function putBigUint32(val, tbl, index)
	for i = 0, 3 do
		tbl[index + i] = bit.band(bit.rshift(val, (3 - i) * 8), 0xFF)
	end
end

function Png:writeBytes(data, index, len)
	index = index or 1
	len = len or #data
	for i = index, index + len - 1 do
		table.insert(self.output, string.char(data[i]))
	end
end

function Png:write(pixels)
	local count = #pixels -- Byte count
	local pixelPointer = 1
	while count > 0 do
		if self.positionY >= self.height then
			error("All image pixels already written")
		end

		if self.deflateFilled == 0 then -- Start DEFLATE block
			local size = DEFLATE_MAX_BLOCK_SIZE
			if self.uncompRemain < size then
				size = self.uncompRemain
			end
			local header = { -- 5 bytes long
				bit.band((self.uncompRemain <= DEFLATE_MAX_BLOCK_SIZE and 1 or 0), 0xFF),
				bit.band(bit.rshift(size, 0), 0xFF),
				bit.band(bit.rshift(size, 8), 0xFF),
				bit.band(bit.bxor(bit.rshift(size, 0), 0xFF), 0xFF),
				bit.band(bit.bxor(bit.rshift(size, 8), 0xFF), 0xFF),
			}
			self:writeBytes(header)
			self:crc32(header, 1, #header)
		end
		assert(self.positionX < self.lineSize and self.deflateFilled < DEFLATE_MAX_BLOCK_SIZE)

		if self.positionX == 0 then -- Beginning of line - write filter method byte
			local b = { 0 }
			self:writeBytes(b)
			self:crc32(b, 1, 1)
			self:adler32(b, 1, 1)
			self.positionX = self.positionX + 1
			self.uncompRemain = self.uncompRemain - 1
			self.deflateFilled = self.deflateFilled + 1
		else -- Write some pixel bytes for current line
			local n = DEFLATE_MAX_BLOCK_SIZE - self.deflateFilled
			if self.lineSize - self.positionX < n then
				n = self.lineSize - self.positionX
			end
			if count < n then
				n = count
			end
			assert(n > 0)

			self:writeBytes(pixels, pixelPointer, n)

			-- Update checksums
			self:crc32(pixels, pixelPointer, n)
			self:adler32(pixels, pixelPointer, n)

			-- Increment positions
			count = count - n
			pixelPointer = pixelPointer + n
			self.positionX = self.positionX + n
			self.uncompRemain = self.uncompRemain - n
			self.deflateFilled = self.deflateFilled + n
		end

		if self.deflateFilled >= DEFLATE_MAX_BLOCK_SIZE then
			self.deflateFilled = 0 -- End current block
		end

		if self.positionX == self.lineSize then -- Increment line
			self.positionX = 0
			self.positionY = self.positionY + 1
			if self.positionY == self.height then -- Reached end of pixels
				local footer = { -- 20 bytes long
					0,
					0,
					0,
					0, -- DEFLATE Adler-32 placeholder
					0,
					0,
					0,
					0, -- IDAT CRC-32 placeholder
					-- IEND chunk
					0x00,
					0x00,
					0x00,
					0x00,
					0x49,
					0x45,
					0x4E,
					0x44,
					0xAE,
					0x42,
					0x60,
					0x82,
				}
				putBigUint32(self.adler, footer, 1)
				self:crc32(footer, 1, 4)
				putBigUint32(self.crc, footer, 5)
				self:writeBytes(footer)
				self.done = true
			end
		end
	end
end

function Png:crc32(data, index, len)
	self.crc = bit.bnot(self.crc)
	for i = index, index + len - 1 do
		local byte = data[i]
		for j = 0, 7 do -- Inefficient bitwise implementation, instead of table-based
			local nbit = bit.band(bit.bxor(self.crc, bit.rshift(byte, j)), 1)
			self.crc = bit.bxor(bit.rshift(self.crc, 1), bit.band(-nbit, 0xEDB88320))
		end
	end
	self.crc = bit.bnot(self.crc)
end
function Png:adler32(data, index, len)
	local s1 = bit.band(self.adler, 0xFFFF)
	local s2 = bit.rshift(self.adler, 16)
	for i = index, index + len - 1 do
		s1 = (s1 + data[i]) % 65521
		s2 = (s2 + s1) % 65521
	end
	self.adler = bit.bor(bit.lshift(s2, 16), s1)
end

local function begin(width, height, colorMode)
	-- Default to rgb
	colorMode = colorMode or "rgb"

	-- Determine bytes per pixel and the PNG internal color type
	local bytesPerPixel, colorType
	if colorMode == "rgb" then
		bytesPerPixel, colorType = 3, 2
	elseif colorMode == "rgba" then
		bytesPerPixel, colorType = 4, 6
	else
		error("Invalid colorMode")
	end

	local state = setmetatable({ width = width, height = height, done = false, output = {} }, Png)

	-- Compute and check data siezs
	state.lineSize = width * bytesPerPixel + 1
	-- TODO: check if lineSize too big

	state.uncompRemain = state.lineSize * height

	local numBlocks = math.ceil(state.uncompRemain / DEFLATE_MAX_BLOCK_SIZE)

	-- 5 bytes per DEFLATE uncompressed block header, 2 bytes for zlib header, 4 bytes for zlib Adler-32 footer
	local idatSize = numBlocks * 5 + 6
	idatSize = idatSize + state.uncompRemain

	-- TODO check if idatSize too big

	local header = { -- 43 bytes long
		-- PNG header
		0x89,
		0x50,
		0x4E,
		0x47,
		0x0D,
		0x0A,
		0x1A,
		0x0A,
		-- IHDR chunk
		0x00,
		0x00,
		0x00,
		0x0D,
		0x49,
		0x48,
		0x44,
		0x52,
		0,
		0,
		0,
		0, -- 'width' placeholder
		0,
		0,
		0,
		0, -- 'height' placeholder
		0x08,
		colorType,
		0x00,
		0x00,
		0x00,
		0,
		0,
		0,
		0, -- IHDR CRC-32 placeholder
		-- IDAT chunk
		0,
		0,
		0,
		0, -- 'idatSize' placeholder
		0x49,
		0x44,
		0x41,
		0x54,
		-- DEFLATE data
		0x08,
		0x1D,
	}
	putBigUint32(width, header, 17)
	putBigUint32(height, header, 21)
	putBigUint32(idatSize, header, 34)

	state.crc = 0
	state:crc32(header, 13, 17)
	putBigUint32(state.crc, header, 30)
	state:writeBytes(header)

	state.crc = 0
	state:crc32(header, 38, 6) -- 0xD7245B6B
	state.adler = 1

	state.positionX = 0
	state.positionY = 0
	state.deflateFilled = 0

	return state
end

local function encode(width: number, height: number, pixels: { number }): string
	local png = begin(width, height, "rgba")

	for i = 1, #pixels, 4 do
		png:write({ pixels[i + 0], pixels[i + 1], pixels[i + 2], pixels[i + 3] })
	end

	assert(png.done)
	return png.output
end

return encode
