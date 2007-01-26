----------------------------------------------------------------------------------------
-- range fucker by bastya_elvtars (the rock n' roll doctor)
-- it was standalone, but got into lawmaker as well.
-- some code from easyranger by tezlo
-- checks if ips are valid and if ranges are really ranges :D
-- thx go out to Herodes for IP validation, Typhoon for paying attention, and plop for finding the bug i couldn't
-- also thx to NightLitch, i always wanna make same scripts as him but much bettter ones :D
-- and to nerbos for his ranger ;-)
-- enjoy

--------------------------------------------------------------------
--------------------------------------------------------------------
-- BOT USAGE AND EXPLANATION OF SETTINGS:
--------------------------------------------------------------------
--------------------------------------------------------------------
-- I have hacked together a quick howto at
-- http://lawmaker.no-ip.org/pages/manuals/rangefucker-v3-manual.php

--------------------------------------------------------------------
--------------------------------------------------------------------
-- CONFIGURATION SECTION:
--------------------------------------------------------------------
--------------------------------------------------------------------

-- Fully ban ranges or not? (0/1)
FullBanRanges=1

-- Permissions
Levels= {
    RangeBan=5, -- ban a range
    RangeTBan=5, -- timeban a range
    RangeUnBan=5, -- unban a range
    RangeTUnBan=5, -- 'untimeban' a range
    SearchTemp=4, -- search among tempbanned ranges
    SearchPerm=4, -- search among permbanned ranges
  }
  
-- Name for the righclick parent menu
RightClickMenuName="RangeFucker" 

-- Bot's data
Bot= {
	 name="-RangeFucker-",
	 desc="IPRange Helper Bot",
   email="rangefucker@localhost",
	 visible=1, -- Reg the bot into userlist? 0/1
  }

-- Only edit below if you know what you are doing.
--------------------------------------------------
userlevels={ [-1] = 1, [0] = 5, [1] = 4, [2] = 3, [3] = 2 }
rightclick={}
rctosend={{}, {}, {}, {}, {}}
commandtable={}
Engine={}
_rightclick=
  {
    __newindex=function(tbl,raw,level)
      for strength,tbl in ipairs(rctosend) do
        if strength>=level then table.insert(rctosend[strength],raw) end
      end
    end
  }

-- Loading the required modules.
-- package.path="./scripts"
require "scripts.rangefucker.bit"
require "scripts.rangefucker.netmask"

function Main()
	if Bot.visible==1 then frmHub:RegBot(Bot.name, 1, Bot.desc, Bot.email) end
	for idx,tbl in ipairs(rctosend) do table.sort(rctosend[idx]); end
  SetTimer(1000)
  StartTimer()
end

function ToArrival(user,data)
  data=data:sub(1,data:len()-1)
  return parsecmds(user,data,"PM",Bot.name)
end

function ChatArrival(user,data)
  data=data:sub(1,data:len()-1)
  return parsecmds(user,data,"MAIN",Bot.name)
end

function NewUserConnected(user)
   if  user.bUserCommand then -- if login is successful, and usercommands can be sent
      user:SendData(table.concat(rctosend[userlevels[user.iProfile]],"|"))
   end
end

OpConnected=NewUserConnected

function parsecmds(user,data,env,bot)
  local cmd = data:match("%b<>%s+[%!%+%#%?%-](%S+)")
  if not cmd then return end
  if commandtable[cmd] then -- if it exists
    local m = commandtable[cmd]
    if m.level~=0 then -- and enabled
      if userlevels[user.iProfile] >= m.level then -- and user has enough rights
        m.func(user,data,env,unpack(m.parms))
      else
        SendTxt(user,env,bot,"You are not allowed to use this command.")
      end
    else
      SendTxt(user,env,bot,"The command you tried to use is disabled now. Contact the hubowner if you want it back.")
    end
    return 1
  end
end

function SendTxt(user,env,bot,text) -- sends message according to environment (main or pm)
  if user.SendPM and user.SendData then
    if env=="PM" then
      user:SendPM(bot,text)
    else
      user:SendData(bot,text)
    end
  end
end

function minutestoh(minutes) -- gets minutes as arguments, returns a string with formatted time and 4 numbers as units
  if frac(minutes) > 0.5 then minutes=math.ceil(minutes) else minutes=math.floor(minutes) end
  local weeks,days,hours,mins
  local msg=""
  local a1,a2,a3=math.modf(minutes,10080),math.modf(minutes,1440),math.modf(minutes,60)
  if a1==minutes then weeks=0 else weeks=math.floor(minutes/10080) end
  if a2==minutes then days=0 else days=math.floor(a1/1440) end
  if a3==minutes then hours=0 else hours=math.floor(a2/60) end
  mins=math.modf(minutes,60)
  local tmp=
      {
	[" weeks "]=weeks,
	[" days "]=days,
	[" hours "]=hours,
	[" minutes"]=mins
      }
      local tmp2={" weeks "," days "," hours "," minutes"}
  for a,b in ipairs(tmp2) do
    if tmp[b] > 0 then
      msg=msg..tmp[b]..b
    end
  end
  if msg=="" then msg="0" end
  return msg,weeks,days,hours,mins
end

function frac(num) -- returns fraction of a number (RabidWombat)
  return num - math.floor(num);
end

function BanRange(user,data,env,bTemp)
  local data=data
  local ip,cidr,amount,unit,reason,mask
  if bTemp then
    ip,cidr,amount,unit = data:match("%b<>%s+%S+%s+(%d+%.%d+%.%d+%.%d+)%/(%d+)%s+(%d+)([MmHhDdWw])")
    if not cidr then
      ip,mask,amount,unit = data:match("%b<>%s+%S+%s+(%d+%.%d+%.%d+%.%d+)%/(%d+%.%d+%.%d+%.%d+)%s+(%d+)([MmHhDdWw])")
    end
    reason=data:match("%b<>%s+%S+%s+%S+%s+%d+[MmHhDdWw]%s+(.+)")
  else
    ip,mask=data:match("%b<>%s+%S+%s+(%d+%.%d+%.%d+%.%d+)%/(%d+%.%d+%.%d+%.%d+)")
    if not mask then
      ip,cidr=data:match("%b<>%s+%S+%s+(%d+%.%d+%.%d+%.%d+)%/(%d+)")
    end
    reason=data:match("%b<>%s+%S+%s+%S+%s+(.+)")
  end
  local mult=
    {
      ["m"]={"minutes",1},
      ["M"]={"minutes",1},
      ["h"]={"hours",60},
      ["H"]={"hours",60},
      ["d"]={"days",1440},
      ["D"]={"days",1440},
      ["w"]={"weeks",1440*7},
      ["W"]={"weeks",1440*7},
    }
  if not (mask or cidr) then
    if data:find("%b<>%s+%S+%s+%d+%.%d+%.%d+%.%d+%-%d+%.%d+%.%d+%.%d+") then
      local ip1,ip2,amount,unit,reason
      if bTemp then
        ip1,ip2,amount,unit=data:match("%b<>%s+%S+%s+(%d+%.%d+%.%d+%.%d+)%-(%d+%.%d+%.%d+%.%d+)%s+(%d+)([MmHhDdWw])")
        reason=data:match("%b<>%s+%S+%s+%S+%-%S+%s+%S+%s+(.+)")
      else
        ip1,ip2=data:match("%b<>%s+%S+%s+(%d+%.%d+%.%d+%.%d+)%-(%d+%.%d+%.%d+%.%d+)")
        reason=data:match("%b<>%s+%S+%s+%S+%-%S+%s+(.+)")
      end
      local c1,c2; if ip1 and ip2 then c1=netmask.iptodecbin(ip1); c2=netmask.iptodecbin(ip2) end
      if c1 and c2 and c1 < c2 then
        if not Btemp then
          local tail; if reason then tail=reason else tail="unspecified"; reason="" end
          RangeBan(ip1, ip2, reason, user.sName, FullBanRanges)
          SendTxt(user,env,Bot.name,"Range "..ip1.."-"..ip2.." banned. Reason: "..tail)
        else
          local u,minz=unpack(mult[unit])
          local tail; if reason then tail=reason else tail="unspecified"; reason="" end
          RangeTempBan(ip1, ip2, minz, reason, user.sName, FullBanRanges)
          SendTxt(user,env,Bot.name,"Range "..ip1.."-"..ip2.." banned for "..amount.." "..u..". Reason: "..tail)
        end
      else
        SendTxt(user,env,Bot.name,"Invalid range! "..ip1.."-"..ip2)
      end
    else
      SendTxt(user,env,Bot.name,"Incorrect usage! Use !banrange <range/CIDRnotation/masknotation> and you have to specify valid IPs or CIDRs or masks (and the time if tempban)!")
    end
  elseif cidr then
    cidr=tonumber(cidr)
    if cidr < 1 or cidr > 32 then
      SendTxt(user,env,Bot.name,"Invalid CIDR notation, can only be 1-32!"); return
    elseif not decip then
      SendTxt(user,env,Bot.name,"Invalid IP! Please check and retry! ;-)"); return
    else
      local decip=netmask.iptodecbin(ip)
      local nmask=bit.tonumb(netmask.calcmaskfromcidr(cidr))
      local res_start,res_end=netmask.getrange(decip,nmask)
      -- We are RFC-1518 compliant! (now really, GeceBekcisi can stop whining at last :-P) :)
      if not Btemp then
        local tail; if reason then tail=reason else tail="unspecified"; reason="" end
        RangeBan(res_start,res_end, reason, user.sName, FullBanRanges)
        SendTxt(user,env,Bot.name,"Range "..ip.."/"..cidr.." ("..res_start.."-"..res_end.." banned. Reason: "..tail)
      else
        local u,minz=unpack(mult[unit])
        minz=minz*amount
        local tail; if reason then tail=reason else tail="unspecified"; reason="" end
        RangeTempBan(res_start,res_end, minz, reason, user.sName, FullBanRanges)
        SendTxt(user,env,Bot.name,"Range "..ip.."/"..cidr.." ("..res_start.."-"..res_end.." banned for "..amount.." "..u..". Reason: "..tail)
      end
    end
  elseif mask then
    local decip=netmask.iptodecbin(ip)
    local nmask=netmask.iptodecbin(mask)
    if not nmask then
      SendTxt(user,env,Bot.name,"Invalid netmask! Please check and retry! ;)"); return
    elseif not decip then
      SendTxt(user,env,Bot.name,"Invalid IP! Please check and retry! ;-)"); return
    end
    local res_start,res_end=netmask.getrange(decip,nmask)
    if not bTemp then
      local tail; if reason then tail=reason else tail="unspecified"; reason="" end
      RangeBan(res_start, res_end, reason, user.sName, FullBanRanges)
      SendTxt(user,env,Bot.name,"Range "..ip.."/"..mask.." ("..res_start.."-"..res_end..") banned. Reason: "..tail)
    else
      local u,minz=unpack(mult[unit])
      minz=minz*amount
      local tail; if reason then tail=reason else tail="unspecified"; reason="" end
      RangeTempBan(res_start, res_end, minz, reason, user.sName, FullBanRanges)
      SendTxt(user,env,Bot.name,"Range "..ip.."/"..mask.." ("..res_start.."-"..res_end..") banned for "..amount.." "..u..". Reason: "..tail)
    end
  end
end

function UnBanRange(user,data,env,bTemp)
  local ip1,ip2=data:match("%b<>%s+%S+%s+(%d+%.%d+%.%d+%.%d+)%-(%d+%.%d+%.%d+%.%d+)")
  if ip1 and ip2 then
    if bTemp then
      RangeTempUnban(ip1, ip2)
    else
      RangeUnban(ip1, ip2)
    end
    SendTxt(user,env,Bot.name,"Range "..ip1.."-"..ip2.." unbanned (if it was banned at all :-P).")
  else
    SendTxt(user,env,Bot.name,"Incorrect usage! Use: !unbanrange xxx.xxx.xxx.xxx-yyy.yyy.yyy.yyy")
  end
end

function Search(user,data,env,bTemp)
  local list=frmHub:GetPermRangeBans() if bTemp then list=frmHub:GetTempRangeBans() end
  local srchstring=data:match("%b<>%s+%S+%s+(.+)")
  local msg=""
  if srchstring then
    for _,obj in ipairs(list) do
      for _,thingy in ipairs({obj.sBy, obj.sIPFrom, obj.sIPTo, obj.sReason}) do
        if thingy:find(srchstring,1,true) then
          msg=msg.."\r\n========================\r\nFound: "..obj.sIPFrom.."-"..obj.sIPTo.." (banned by "..obj.sBy..")."
          if obj.sReason then msg=msg.." - Reason: "..obj.sReason end
          if obj.iTime then msg=msg.." - Time remaining: "..minutestoh(math.ceil(obj.iTime/60)) end
          msg=msg.."\r\n========================"
        end
      end
    end
    if msg~="" then user:SendPM(Bot.name,msg) else SendTxt(user,env,Bot.name,"No matches found for "..srchstring) end
  else
    SendTxt(user,env,Bot.name,"Need a search string too! :P")
  end
end

function RegRC(level,context,name,command,PM)
  if level==0 or level==nil then return end
	setmetatable(rightclick,_rightclick)
  if not PM then
    rightclick["$UserCommand "..context.." "..RightClickMenuName.."\\"..name.."$<%[mynick]> "..command.."&#124;"]=level
  else
    rightclick["$UserCommand "..context.." "..RightClickMenuName.."\\"..name.."$$To: "..Bot.name.." From: %[mynick] $<%[mynick]> "..command.."&#124;"]=level
  end
end

do
  local Engine={}
  setmetatable (Engine,{ -- The metatable for commands engine.
    __newindex=function(tbl,cmd,stuff)
      local a,b,c,d=unpack(stuff)
      commandtable[cmd]={["func"]=a,["parms"]=b,["level"]=c,["help"]=d}
    end
  })
  Engine["banrange"]={BanRange, {false}, Levels.RangeBan,"<range/CIDRnotation/masknotation> // Bans an IP range."}
  Engine["tbanrange"]={BanRange, {true}, Levels.RangeTBan, "<range/CIDRnotation/masknotation> <count><hmsDW>// Temp. bans an IP range."}
  Engine["searchranges"]={Search, {false}, Levels.SearchPerm, " // Search among banned IP ranges."}
  Engine["searchtranges"]={Search, {true}, Levels.SearchTemp, " // Search among temporarily banned IP ranges."}
  Engine["unbanrange"]={UnBanRange, {false}, Levels.RangeUnBan, "<IP1-IP2> // Unbans a banned IP range."}
  Engine["untbanrange"]={UnBanRange, {true}, Levels.RangeTUnBan, "<IP1-IP2> // Unbans a temp. banned IP range."}
end

RegRC(Levels.RangeBan,"1 3","Ban a range...","!banrange %[line:Start IP:]-%[line:End IP:] %[line:Reason (optional):]")
RegRC(Levels.RangeBan,"1 3","Ban a range with CIDR...","!banrange %[line:IP:]/%[line:CIDR:] %[line:Reason (optional):]")
RegRC(Levels.RangeBan,"1 3","Ban a range with netmask...","!banrange %[line:IP:]/%[line:Netmask:] %[line:Reason (optional):]")
RegRC(Levels.RangeTBan,"1 3","Tempban a range...","!tbanrange %[line:Start IP:] %[line:End IP:] %[line:Reason (optional):]")
RegRC(Levels.RangeTBan,"1 3","Tempban a range with CIDR...","!tbanrange %[line:IP:]/%[line:CIDR:] %[line:Reason (optional):]")
RegRC(Levels.RangeTBan,"1 3","Tempban a range with netmask...","!tbanrange %[line:IP:]/%[line:Netmask:] %[line:Reason (optional):]")
RegRC(Levels.RangeUnBan,"1 3","UnBan a range...","!unbanrange %[line:Start IP:] %[line:End IP:]")
RegRC(Levels.RangeTUnBan,"1 3","UnTempBan a range...","!untbanrange %[line:Start IP:] %[line:End IP:]")
RegRC(Levels.SearchPerm,"1 3","Search among banned IP ranges","!searchranges")
RegRC(Levels.SearchTemp,"1 3","Search among tempbanned IP ranges","!searchtranges")

-- (c) 2003-2007 bastya_elvtars