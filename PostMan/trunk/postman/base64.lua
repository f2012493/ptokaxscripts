-- lua base64 encoder/decoder (c) 2006 by Alex Kloss
-- Compatible with Lua 5.1 (not 5.0).
-- http://www.it-rfc.de

-- Fucked with a bit by bastya_elvtars, 2007-01-15

-- function byte64
-- translate a 6bit-number to a base64 character
function byte64(byte)
  if (byte == nil) then result = "="
  elseif (byte <= 25) then result = string.char(65+byte)
  elseif (byte <= 51) then result = string.char(71+byte)
  elseif (byte <= 61) then result = string.char(byte-4)
  elseif (byte == 62) then result = "-"
  elseif (byte == 63) then result = "_"
  else result = nil end
  return result
end

-- function encodeblock
-- encodes a 3 bytes long input string block to 4 base64 characters.
function encodeblock(block)
  local result = ""
  local bytes = {}
  local sixbits = {}
  for byte=1,3 do bytes[byte] = string.byte(block:sub(byte)) or 0 end
  sixbits[1] = byte64(math.floor(bytes[1]/4))
  sixbits[2] = byte64((bytes[1] % 4) * 16 + math.floor(bytes[2] / 16))
  if ((block):len() > 1) then
    sixbits[3] = byte64((bytes[2] % 16) * 4 + math.floor(bytes[3] / 64))
  else
    sixbits[3] = "="
  end
  if ((block):len() > 2) then
    sixbits[4] = byte64(bytes[3] % 64)
  else
    sixbits[4] = "="
  end
  for nr,sixbit in pairs(sixbits) do
    result = result .. sixbit
  end 
  return result
end

-- function encode
-- encodes input string to base64
function encode(input)
  local result = ""
  for c=1,input:len(),3 do
    result = result .. encodeblock(input:sub(c,c+2))
  end
  return result
end

-- function 6bit
-- returns the 6bit value of a base64 character
function sixbit(char)
  local byte = char:byte()
  local result = nil
  if (byte == 61) then result = 0
  elseif (byte == 45 or byte == 43) then result = 62
  elseif (byte == 95 or byte == 47) then result = 63
  elseif (byte <= 57) then result = byte + 4
  elseif (byte <= 90) then result = byte - 65
  elseif (byte <= 122) then result = byte - 71
  end
  return result
end

-- function decodeblock
-- decodes a 4 byte base64 block to a 3 byte string block
function decodeblock(block)
  local sixbits = {}
  local result = ""
  for counter=1,4 do sixbits[counter] = sixbit(block:sub(counter,counter)) end
  result = string.char(sixbits[1]*4 + math.floor(sixbits[2] / 16))
  if (string.sub(block,3,3) ~= "=") then
    result = result .. string.char((sixbits[2] % 16)*16 + math.floor(sixbits[3] / 4))
  end
  if (block:sub(4,4) ~= "=") then
    result = result .. string.char((sixbits[3] % 4) * 64 + sixbits[4])
  end
  return result
end

-- function decode
-- Decodes base64-encoded data
function decode(data)
  local result = ""
  for c=1,data:len(),4 do
    result = result .. decodeblock(data:sub(c,c+3))
  end
  return result
end