--[[
netmask calculation routine for RangeFucker
Does many things:
- gets a range from netmask, cidr
- converts IPs to and from binary/decimal/dotted formats

References:

http://library.thinkquest.org/28289/subnet.html
http://www.ipprimer.com/bitbybit.cfm

Uses the LuaBit library by Han Zhao: http://luaforge.net/projects/bit/
To load LuaBit library: edit package.path accordingly.
Thanks to chill and CrazyGuy for hints.
bastya_elvtars
]]

module("netmask",package.seeall)


package.path="I:/luabit/?.lua"
require "bit"

function iptodecbin(ip)
  local err
  local c=256^3
	local decip=0
  for b in string.gmatch(ip,"(%d+)") do
    local piece=tonumber(b)
    if not piece or piece > 255 then
      err=true
      break
    else
      decip=decip+(piece*c)
      c=c/256
    end
  end
  if not err then
    return decip,bit.tobits(decip)
  end
end

function dectoip(ip)
  local tmp
  local pt1,pt2,pt3,pt4
  pt1=math.modf((ip)/256^3)
  tmp=math.fmod((ip),256^3)
  pt2=math.modf((tmp)/256^2)
  tmp=math.fmod(tmp,256^2)
  pt3=math.modf((tmp)/256)
  pt4=math.fmod(tmp,256)
  return pt1.."."..pt2.."."..pt3.."."..pt4
end

function calcmaskfromcidr(CIDR)
  if CIDR < 33 then
    local bittbl={}
    local counter=0
    for k=1,32 do
      if counter == 32 then break end -- we reached 32 bits
      counter=counter+1
      if counter <= CIDR then
        table.insert(bittbl,1)
      else
        table.insert(bittbl,1,0)
      end
    end
    if #bittbl==32 then return bittbl end
  end
end 

function getrange(decip,decmask)
  return dectoip(bit.band(decip,decmask)),dectoip(bit.bor(decip,bit.bnot(decmask)))
end