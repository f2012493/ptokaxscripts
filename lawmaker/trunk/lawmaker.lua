--[[About
LawMaker - a bot for PtokaX DC Hub
Copyright (C) 2004-2005 bastya_elvtars (bastyaelvtars@gmail.com)

Website: http://lawmaker.no-ip.org/

The license does not apply for the sample text files included in the default package.
Those files are not considered as part of the standard package, just examples.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
---------------------------------------------------------------------------------------------------
CREDITS 
Some ideas in LMCA by plop & NightLitch (however it was totally written from scratch).
Please see the help file(s) included on cofiguring the bot.
Thanks to: 
----------
  First of all:  my beautiful girlfriend.
  
  For PtokaX: Ptaczek/PPK/aMutex/frontline3k
  
  LUA 5 (and later) Copyright © 1994-2005 Lua.org, PUC-Rio
  
  For inspiration:
  
  plop (Artificial Insanity)
  Nathanos (Channelbot)
  tezlo (RetroBot)
  OpiumVolage (ModBot)
  
  For help:
  
  plop, PPK, NightLitch, RabidWombat, Herodes, tezlo, jiten, Dessamator, BottledHate, Hawk, Optimus, GeceBekcisi,
  TTB, Mutor, kepp, chilla, Nathanos, Skrollster, Sedulus, nErBoS, Skippy84, psf8500, Typhoon, yepyepyep4711
  And yes, thx to others in LUA Hub, LUA Board(s) and DCDev (not a mistake) that I forgot now.
  There are detailed credits in plugins.
  
  For testing:
  
  TiMeTrAVelleR, Psycho_Chihuahua
  Nidaros, Libbe, Darkstar and other Golden Angel ops,
  zinden, kaotkbliss and all the ops of PC Gamers,
  Mickey, Makavelli-2Pac, 6Marilyn6Manson6, LiqUiD~TrolL,
  Bumbi, GrinSlaw, gander
  
  Special thanks to:
  
  Neil Hodgson, creator of SciTE, a GREAT & FREE editor (http://www.scintilla.org)
  OpiumVolage, the primary LUA board hoster (http://board.univ-angers.fr)
  Matt, the secondary LUA board hoster (http://lua.uknnet.com)
  Psycho_Chihuahua, host of PtokaX Wiki (http://ptxwiki.psycho-chihuahua.net/) and PtokaX Script Database (http://ptxscriptdb.psycho-chihuahua.net/)
  [NL]Pur, who established the Moon5 project at Sourceforge.
  
----------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------  
]]
--====================
--== SETTINGS
--====================
-- BASIC SETTINGS
-- all should be easy ;)

-- Place any directories that contain setting scripts that your script uses between these tags
--<SettingsDirectoriesStart>
--\lawmaker\components\cfg
--<SettingsDirectoriesEnd>
--<SettingsStart>
founder="bastya_elvtars" -- Hub founder's name, exact nick please!!!
owner="U" -- Hub owner's name, exact nick please!!!

Bot={ 
      name="-LawMaker-",
      desc="Main Hub Bot",
      email="lawmaker@lawmaker.lua", -- equal to the hub's e-mail addy
} -- Bot's data

autoreg=1 -- 0 do disable, 1 to enable autoreg on various hublist servers

complaint=2 -- Adress sent to perm/temp banned user. 0=nothing, 1=e-mail (the bot's mail address), 2=website
hubwebsite="www.your-hubs-site.net" -- Replace with your hub's website. Will be sent on ban.
complainttext="You may cry a river at: " -- text before the sent addyű

debug_log=1 -- Logs debug messages. Please leave it enabled.
debug_send=1 -- PMs specified users on error. See the next setting.
debug_sendto={ 
  "[TGA-OP]bastya_elvtars", 
  "bastya_elvtars",
} -- Specify the usernames that you want the errormessages to be sent to.

rightclick_menuname="-LawMaker-" -- Name of the parent menu for rightclick commands.
--<SettingsEnd>
-------------------------------------------------------------------------------------
-- END OF BASIC SETTINGS, NO EDITING NEEDED BELOW THIS POINT UNLESS YOU FIND A BUG --
-------------------------------------------------------------------------------------

-- If there is an error with a plugin, the error will be sent to ops, script won't crash.

-- Functions related to Ptokax events

gb=1024*1024*1024 -- one gigabyte in bytes

tNUCOrder= -- order of funcs to be called on NewUser(Op)Connected
  {
    "check ip range",
    "on-connect check",
    "add/refresh user in database",
    "random welcome message",
    "showing motd",
    "new message warning on connect",
    "announcing new releases",
    "sending opchat/vipchat history rightclk",
  }

rightclick={}
rctosend={}
commandtable={}
lagtest={}
modules={}

path="lawmaker/components/"

function Main()
  local x=os.clock()
  os.execute("dir \""..frmHub: GetPtokaXLocation().."scripts/lawmaker/components\" /b /o:n > \""..frmHub: GetPtokaXLocation().."scripts/lawmaker/components.lst\"")
  local f=io.open("lawmaker/components.lst","r")
--   local f=io.popen("dir \""..frmHub: GetPtokaXLocation().."scripts/lawmaker/components\" /b /o:n > \""..frmHub: GetPtokaXLocation().."scripts/lawmaker/components.lst\"","r")
  local count=0
  for line in f:lines() do
    if string.find(line,"%.lmc$") and string.sub(line,1,1)~="_" then
      local _,err=loadfile("lawmaker/components/"..line)
      if not err then
	count=count+1
	dofile("lawmaker/components/"..line)
-- 	SendToAll(Bot.name,"Loaded "..line)
      else
        SendToOps("ERROR:","******************************************************** <***>")
	SendToOps("ERROR:",err)
	SendToOps("ERROR:","******************************************************** <***>")
      end
    end
  end
  os.remove(frmHub: GetPtokaXLocation().."scripts/lawmaker/components.lst")
  assert((count > 0),"Fatal error, no components found.")
  Bot.version="LawMaker 1.0 alpha (LMCA) by bastya_elvtars (the rock n' roll doctor)" 
  frmHub:SetOpChat(0)
  frmHub:SetHubBot(1)
  frmHub:SetAutoRegister(autoreg)
  frmHub:SetPrefixes("!+#?-")
  if not string.find(frmHub:GetHubDescr()," %- powered by LawMaker") then
    frmHub:SetHubDescr(frmHub:GetHubDescr().." - powered by LawMaker")
    -- I know many will remove this, but I still won't compile the bot. :)
  end
  frmHub:SetHubBotData(Bot.name, Bot.desc, Bot.email)
  frmHub:SetHubBotIsAlias(1)
  SetTimer(1000)
  StartTimer()
  for _,name in pairs(modules.main) do
    name.func(unpack(name.parms))
  end
  -- this is to make sure hub perceives !help. :)
  RegCmd("help",help,{},1,"\t\t\t\t\t\tShows the text you are looking at.")
  RegCmd("license",license,{},1,"\t\t\t\t\t\tShows the license agreement (GNU GPL).")
  RegCmd("lagtest",lagtestonoff,{},1,"\t\t\t\t\t\tShows processing time of a commands.")
  RegRC(1,"1 3","Help","!help")
  RegRC(1,"1 3","Lagtest\\Enable","!lagtest on")
  RegRC(1,"1 3","Lagtest\\Disable","!lagtest off")
  RegRC(1,"1 3","License agreement (GPL)","+license")
  CreateRightClicks()
  SendToOps(Bot.name,"Bootup finished, took "..os.clock()-x.." seconds, "..count.." plugins have been loaded.")
end

function OnTimer()
  for _,name in pairs(modules.ont) do -- runs through the funcs to be called now
    name.func (unpack(name.parms))
  end
end

function NewUserConnected(user)
  local bad
  for _,todo in ipairs(tNUCOrder) do
    local name=modules.nuc[todo]
    if modules.nuc[todo] then
      if name.func(user,unpack(name.parms))=="shit" then
	bad=true
	return 1
      end
    end
  end
  if not bad then -- is this necessary at all? :-S
    user:SendData(Bot.name,"Welcome to "..frmHub:GetHubName()..", enjoy your stay, happy chatting and downloading!")
    user:SendData(Bot.name,"Type !help in mainchat or in PM session with me to see the commands you can use.")
    if  user.bUserCommand then -- if login is successful, and usercommands can be sent
      user:SendData(table.concat(rctosend[user.iProfile],"|"))
      user:SendData(Bot.name,"You just got "..(table.getn(rctosend[user.iProfile])).." rightclick commands, come on, unleash my full power! :)")
    end
    user:SendData(Bot.name,Bot.version..". Licensed under the GNU GPL, type +license for details.")
  end
end

function ToArrival(user,data)
  data=string.sub(data,1,string.len(data)-1)
  local _,_,whoto,cmd = string.find(data,"$To:%s+(%S+)%s+From:%s+%S+%s+$%b<>%s+[%!%+%#%?%-](%S+)")
  if commandtable[cmd] then
    local x=os.clock()
    parsecmds(user,data,"PM",string.lower(cmd),whoto)
    if lagtest[user.sName] then SendTxt(user,"PM",Bot.name,"Executing this command took "..os.clock()-x.." seconds.") end
    return 1
  else
    for _,name in pairs(modules.toarr) do -- runs through the funcs to be called now
      if name.func(user,data,unpack(name.parms))=="shit" then return 1 end
    end
  end
end

function ChatArrival(user,data)
  data=string.sub(data,1,string.len(data)-1)
  local _,_,cmd=string.find(data,"%b<>%s+[%!%+%#%?%-](%S+)")
  if commandtable[cmd] then
    local x=os.clock()
    parsecmds(user,data,"MAIN",string.lower(cmd))
    if lagtest[user.sName] then SendTxt(user,"MAIN",Bot.name,"Executing this command took "..os.clock()-x.." seconds.") end
    return 1
  else
    for _,name in pairs(modules.chatarr) do -- runs through the funcs to be called now
      if name.func(user,data,unpack(name.parms))=="shit" then return 1 end
    end
  end
end

function MyINFOArrival (user,data)
  data=string.sub(data,1,string.len(data)-1)
  for _,name in pairs(modules.myinfo) do -- runs through the funcs to be called now
    if name.func(user,data,unpack(name.parms))=="shit" then break end
  end
end

function KickArrival(user,data)
  data=string.sub(data,1,string.len(data)-1)
  for _,name in pairs(modules.kickarr) do -- runs through the funcs to be called now
    if name.func(user,data,unpack(name.parms))=="shit" then return 1 end
  end
end

function OnExit()
  for _,name in pairs(modules.onexit) do -- runs through the funcs to be called now
    name.func(user,data,unpack(name.parms))
  end
end

function UserDisconnected(user)
  for _,name in pairs(modules.userdisc) do -- runs through the funcs to be called now
    name.func(user,unpack(name.parms))
  end
end

function OpForceMoveArrival(user,data)
  for _,name in pairs(modules.forcemovearr) do -- runs through the funcs to be called now
    if name.func(user,data,unpack(name.parms))=="shit" then return 1 end
  end
end

function OnError( err ) -- traceback is unnecessary
  if debug_send==1 then
    for i = 1, table.getn(debug_sendto) do
      SendPmToNick( debug_sendto[i], Bot.name, err)
    end
  end
  if (debug_log==1 and Logging) then Logging.Write( "lawmaker/debug.log", os.date("%Y. %m. %d. %X").."\r\n"..err.."\n-------------------------------");end;
end

function SupportsArrival(User, Data)
end
function KeyArrival(User, Data)
end
function ValidateNickArrival(User, Data)
end
function PasswordArrival(User, Data)
end
function VersionArrival(User, Data)
end
function GetNickListArrival(User, Data)
end
function GetINFOArrival(User, Data)
end
function SearchArrival(User, Data)
end
function ConnectToMeArrival(User, Data)
end
function MultiConnectToMeArrival(User, Data)
end
function RevConnectToMeArrival(User, Data)
end
function SRArrival(User, Data)
end
function UserIPArrival(User, Data)
end
function UnknownArrival(User, Data)
end
function BotINFOArrival(User, Data)	
end	

-- Module registration and command parsing

userlevels={ [-1] = 1, [0] = 5, [1] = 4, [2] = 3, [3] = 2 } -- rights management

function parsecmds(user,data,env,cmd,bot)
  if env~="PM" then bot=Bot.name end
  local name=commandtable[cmd]
  if name then -- if it exists
    if name.level~=0 then -- and enabled
      if userlevels[user.iProfile] >= name.level then -- and user has enough rights
        name.func(user,data,env,unpack(name.parms)) -- user,data,env and more params afterwards
      else
        SendTxt(user,env,bot,"You are not allowed to use this command.")
      end
    else
      SendTxt(user,env,bot,"The command you tried to use is disabled now. Contact the hubowner if you want it back.")
    end
    return 1 -- not to be seen in main
  end
end

function CreateRightClicks()
  for _,idx in {-1,0,1,2,3} do -- usual profiles
    rctosend[idx]=rctosend[idx] or {} -- create if not exist (but this is not SQL :-P)
    for item,level in pairs(rightclick) do -- run thru the rightclick table
      if userlevels[idx] >= level then -- if user is allowed to use
        table.insert(rctosend[idx],item) -- then put to the array
      end
    end
    for _,arr in pairs(rctosend) do -- and we alphabetize (sometimes eyecandy is also necessary)
      table.sort(arr) -- sort the array
    end
  end
end

-- I know function calls introduce some overhead, but these are left for future experiments with Lua 5.1.
----
function RegFunc(when,name,func,params,riteclk) -- Functions to be called on ptokax events :)
  if not modules[when] then modules[when]={} end
  modules[when][name]={["func"]=func,["parms"]=params}
end

function RegCmd(cmnd,func,parms,level,help) -- Regs a command, parsed on ToArrival and ChatArrival
  commandtable[cmnd]={["func"]=func,["parms"]=parms,["level"]=level,["help"]=help}
end

function RegRC(level,context,name,command,PM)
  if level==0 then return 1 end
  if not PM then
    rightclick["$UserCommand "..context.." "..rightclick_menuname.."\\"..name.."$<%[mynick]> "..command.."&#124;"]=level
  else
    rightclick["$UserCommand "..context.." "..rightclick_menuname.."\\"..name.."$$To: "..Bot.name.." From: %[mynick] $<%[mynick]> "..command.."&#124;"]=level
  end
end
----
-- General functions that can be useful in any component.
function maketable(file,separator) -- opens a file and adds its contents to a table.
  local tbl={}
  local f=io.open(file,"r")
  if f then
    for line in f:lines() do
      if not separator then
	tbl[line] = 1
      else
	local _,_,x,y=string.find(line,"(.+)%"..separator.."(.+)") -- note the %
	tbl[x]=tonumber(y) or y
      end
    end
  end 
  return tbl
end

function savefile(tbl,file,separator) -- saves a table into a file
--   SendToAll(file)
  local tmp={}
  local f=io.open(file,"w+")
  for a,b in tbl do
    if not separator then
      table.insert(tmp,a.."\n")
    else
      table.insert(tmp,a..separator..b.."\n")
    end
  end
  f:write(table.concat(tmp))
  f:close()
  tmp=nil; Clear()
end

function getmode(myinfo) -- returns mode name from M: string
  local tofind={["M:A,H:"]="Active",["M:P,H:"]="Passive",["M:[S5],H:"]="Socks5"}
  local mode
  for a,b in tofind do
    if string.find(myinfo,a) then
      mode=b
      break
    end
  end
  mode=mode or "Unknown"
  return mode
end

function SendTxt(user,env,bot,text) -- sends message according to environment (main or pm)
  local to={["PM"]=user.SendPM}
  local todo=to[env] or user.SendData
  todo(user, bot, text)
--   if env=="PM" then
--     user:SendPM(bot,text)
--   else
--     user:SendData(bot,text)
--   end
end

function Clear() -- cleanup
  collectgarbage()
  io.flush()
end

function aah() -- MUHAHA (returns complaint text + hubwebsite/mail/nothing)
  if complaint==1 then
    return ". "..complainttext..Bot.email.."."
  elseif complaint==2 then
    return ". "..complainttext..hubwebsite.."."
  else
    return "."
  end
end

function SplitTimeString(TimeString) 
-- Splits a time format to components, originally written by RabidWombat.
-- Supports 2 time formats: MM/DD/YYYY HH:MM and YYYY. MM. DD. HH:MM
  local D,M,Y,HR,MN,SC
  if string.find(TimeString,"/") then
    _,_,M,D,Y,HR,MN,SC=string.find(TimeString,"(%d+)/(%d+)/(%d+)%s+(%d+):(%d+):(%d+)")
  else
    _,_,Y,M,D,HR,MN,SC = string.find(TimeString, "([^.]+).([^.]+).([^.]+). ([^:]+).([^:]+).(%S+)")
  end
  D = tonumber(D)
  M = tonumber(M)
  Y = tonumber(Y)
  HR = tonumber(HR)
  assert(HR < 24)
  MN = tonumber(MN)
  assert(MN < 60)
  SC = tonumber(SC)
  assert(SC < 60)
  return D,M,Y,HR,MN,SC
end

function JulianDate(DAY, MONTH, YEAR, HOUR, MINUTE, SECOND) -- Written by RabidWombat.
-- HOUR is 24hr format.
  local jy, ja, jm;
  assert(YEAR ~= 0);
  assert(YEAR ~= 1582 or MONTH ~= 10 or DAY < 4 or DAY > 15);
  --The dates 5 through 14 October, 1582, do not exist in the Gregorian system!
  if(YEAR < 0 ) then
    YEAR = YEAR + 1;
  end
  if( MONTH > 2) then 
    jy = YEAR;
    jm = MONTH + 1;
  else
    jy = YEAR - 1;
    jm = MONTH + 13;
  end
  local intgr = math.floor( math.floor(365.25*jy) + math.floor(30.6001*jm) + DAY + 1720995 );
  --check for switch to Gregorian calendar
  local gregcal = 15 + 31*( 10 + 12*1582 );
  if(DAY + 31*(MONTH + 12*YEAR) >= gregcal ) then
    ja = math.floor(0.01*jy);
    intgr = intgr + 2 - ja + math.floor(0.25*ja);
  end
  --correct for half-day offset
  local dayfrac = HOUR / 24 - 0.5;
  if( dayfrac < 0.0 ) then
    dayfrac = dayfrac + 1.0;
    intgr = intgr - 1;
  end
  --now set the fraction of a day
  local frac = dayfrac + (MINUTE + SECOND/60.0)/60.0/24.0;
  --round to nearest second
  local jd0 = (intgr + frac)*100000;
  local  jd  = math.floor(jd0);
  if( jd0 - jd > 0.5 ) then jd = jd + 1 end
  return jd/100000;
end

function frac(num) -- returns fraction of a number (RabidWombat)
  return num - math.floor(num);
end

function minutestoh(minutes) -- gets minutes as arguments, returns a string with formatted time and 4 numbers as units 
if frac(minutes) > 0.5 then minutes=math.ceil(minutes) else minutes=math.floor(minutes) end
local weeks,days,hours,mins
local msg=""
  local a1,a2,a3=math.mod(minutes,10080),math.mod(minutes,1440),math.mod(minutes,60)
  if a1==minutes then weeks=0 else weeks=math.floor(minutes/10080) end
  if a2==minutes then days=0 else days=math.floor(a1/1440) end
  if a3==minutes then hours=0 else hours=math.floor(a2/60) end
  mins=math.mod(minutes,60)
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

-- Converts bytes to human-readable units, returns value (number) and unit (string)
function bytestoh(bytes) -- Returns unformatted value, do a string.format if you would like to.
  local tUnits={"kB","MB","GB","TB","PB"} -- MUST be enough. :D
  local v,u
  for k=table.getn(tUnits),1,-1 do
    if math.mod(bytes,1024^k)~=bytes then v=bytes/(1024^k); u=tUnits[k] break end
  end
  return v or bytes,u or "B"
end


-- help is included in the core.
function help(user,data,env)
  local count=0
  local hlptbl={}
  local hellp=
      {
	["!op <nick>\t\t\t\tGives a temporal Op status to <nick> for one session."]=5,
	["!startscript <filename>\t\t\t\tStarts script with given filename."]=5,
	["!stopscript <filename>\t\t\t\tStops script with given filename."]=5,
	["!restartscript <filename>\t\t\t\tRestarts script with given filename."]=5,
	["!reloadtxt\t\t\t\t\tFReload all textfiles"]=5,
	["!stat\t\t\t\t\tShows some hub statistics."]=1
      }
  local hlp="\r\nCommands available to you are:\r\n=================================================================================================================================\r\n"
  for a,b in commandtable do
    if b["level"]~=0 then
--       SendToAll(a)
      if userlevels[user.iProfile] >= b["level"] then
        count=count+1
        table.insert(hlptbl,"+"..a.." "..b["help"])
      end
    end
  end
  for a,b in hellp do
    if b <= userlevels[user.iProfile] then
      count=count+1
      table.insert(hlptbl,a)
    end
  end
  table.sort(hlptbl)
  hlp=hlp..table.concat(hlptbl,"\r\n").."\r\nAll the "..count.." commands you can use can be typed in main or in PM session with anyone, and the available prefixes are: ! # + - ?\r\n=================================================================================================================================\r\n*** "..Bot.version
  user:SendPM(Bot.name,hlp)
end

function lagtestonoff (user,data,env)
  local _,_,onoff=string.find(data,"%b<>%s+%S+%s+(%S+)")
  if onoff=="on" then
    if not lagtest[user.sName] then
      lagtest[user.sName]=1
      SendTxt(user,env,Bot.name,"You have signed up to lagtesters' list.")
    else
      SendTxt(user,env,Bot.name,"You are already a lagtester")
    end
  elseif onoff=="off" then
    if lagtest[user.sName] then
      lagtest[user.sName]=nil
      SendTxt(user,env,Bot.name,"You have signed off from lagtesters' list.")
    else
      SendTxt(user,env,Bot.name,"You are not a lagtester")
    end
  else
    onoff=onoff or "nothing"
    SendTxt(user,env,Bot.name,"The argument can be on or off, not "..onoff..".")
  end
end

function license(user,data,env)
  local f=io.open("lawmaker/License.txt","r")
  if f then
    local contents = string.gsub(f:read("*a"),string.char(10), "\r\n")
    user:SendPM(Bot.name,"\r\n"..contents.."\r\n")
    f:close()
  else
    SendToAll(Bot.name,"The file License.txt could not be found on this machine, so the GPL is being violated now!")
  end
end

function Run(file)
  local _,err=loadfile(file)
  if not err then
    dofile(file)
--     SendToAll(Bot.name,"Loaded "..file)
  else
    SendToOps("ERROR:","******************************************************** <***>")
    SendToOps("ERROR:",err)
    SendToOps("ERROR:","******************************************************** <***>")
  end
end

-- (dis)connections are global, we do level-based checks on events
OpConnected=NewUserConnected
OpDisconnected=UserDisconnected
--[[
TODO:
- document settings
- document LMCA
- document features
]] 