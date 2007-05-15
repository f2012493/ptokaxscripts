-- Clone Alert 1.7
-- 1.0b by Mutor The Ugly
-- PM Clone login to Opchat
-- Applied to latest PtokaX by bastya_elvtars
-- Also added share checking, if different, only notifies ops.
--thx NightLitch
-- Added: Clone check immunity (add, remove and list immune users) by jiten
--- -- touched by Herodes
-- heavily optimised
-- moved to 1.5
-- now it's 1.6, after bastya_elvtars did some more optimization to the detector. :P

-- 1.7: 
  -- changed: rewrote the clone checking routine, so it no longer loops on every user connecion
  -- added: it also ckecks clones on startup, that makes the hub 100% immune to clones
  -- changed: removed opchatbot detection, using SendToOpChat() instead
  -- added: Socks checking (requested by achiever)

-- 1.7.5:
  -- changed: rewrote the socks routine to a more effective one, thanks achiever

Bot = frmHub:GetHubBotName() -- Rename to you main Px bot
kick = 0 -- 0 to only disconnect, otherwise enter a number, and user will be kicked for that amount of minutes.
kick_other_too=1 -- 1 to disconnect/kick the already logged in user, 0 to not
protect_socks=1 -- set to 0 to handle SOCKS users as others.
                -- This is disrecommended as users between the same proxy usually share the same IP.
PmOps = 1 -- 1:enables / 0:disables  operator notification (STRONGLY recommended to leave enabled!)

_tIPStorage={}
tIPStorage={}
clonedout={}
tImmune = {}

_mtIPStorage=
  {
    __newindex=function(tbl,ip,nick) -- This function gets called when  a new entry is added to _tIPStorage
    -- The value finally gets added to _tIPStorage, hence _tIPStorage is a so-called proxy tanle
    -- See http://www.lua.org/pil/13.4.4.html for detailed explanation
      if tIPStorage[ip] then -- hey, this ip is already in use!
        local User,curUser=GetItemByName(tIPStorage[ip]),GetItemByName(nick) -- now who does it belong to?
        -- curUser refers to the newly connected user, User refers to his clone
        -- you may ask, why we have this since there can be more than 1 clones of a user, but there cannot, cause
        -- they get checked on startup and only 1 can remain, like in Highlander. :-P
        if User then -- yes, the clone is online
          local GetProxyState=function (user,user2)
            -- only 1 user proxied:
            if string.find(user.sMyInfoString,"M:[S5]") and not string.find(user2.sMyInfoString,"M:[S5]") then return 1
            -- both users proxied:
            elseif protect_socks == 1 and string.find(user.sMyInfoString,"M:[S5]") and string.find(user2.sMyInfoString,"M:[S5]") then return 2
            -- none of the 2 are proxied:
            else return 1 end
          end
          local det=function (user,user2)
            user:SendPM(Bot,"Double Login is not allowed. You are already connected to this hub with this nick: "..user2)
            local done
            if kick~=0 then
              done="timebanned for "..kick.." minutes"
              user:SendPM(Bot,"You're being timebanned. Your IP: "..user.sIP)
              user:TimeBan(kick)
            else
              done="disconnected"  
              user:SendPM(Bot,"You're being disconnected.")
              user:Disconnect()
            end
            if PmOps == 1 then
              SendToOpChat("*** Cloned user <"..user.sName.."> ("..user.sIP..") has been found and "..done..". User is a clone of <"..user2..">")
            end
          end
          if not(tImmune[curUser.sName] or tImmune[User.sName]) and not User.bOperator  then
            -- we don't check curUser for being an op, because we do NewUserConnected() and GetOnlineNonOperators()
            -- Users have to meet one of the following criteria:
            --    * SAME SHARE
            --    * ONE OR BOTH OF THEM NON-PROXIED
            if curUser.iShareSize==User.iShareSize and GetProxyState (User,curUser) == 1 then
              local nick1,nick2=curUser.sName,User.sName
              clonedout[curUser.sName]=User.sName -- clonedout[connectedguy]=existantguy - see OnExit()
              det(curUser,nick1)
              if kick_other_too==1 then
                clonedout[User.sName]=curUser.sName -- clonedout[existantguy]=connectedguy - see OnExit()
                det(User,nick2)
              end
            else
              tIPStorage[curUser.sIP]=curUser.sName
              if PmOps == 1 then
                if GetProxyState (User,curUser) == 1 then -- at least one of them is not proxied, else they're considered non-suspicious
                  SendToOpChat("*** A user "..curUser.sName.." hass been found to have the same IP as "..User.sName.." but share sizes are different, please check.")
                  clonedout[User.sName]=curUser.sName
                end
              end
            end
          end
        else
          tIPStorage[curUser.sIP]=curUser.sName
        end
      else
        tIPStorage[ip]=nick
      end
    end
  }

function Main()
  setmetatable(_tIPStorage,_mtIPStorage)
  for _,user in ipairs(frmHub:GetOnlineNonOperators()) do
    _tIPStorage[user.sIP]=user.sName
  end
  if loadfile("logs/cloneimmune.txt") then dofile("logs/cloneimmune.txt"); end
end

function OnExit()
  local f = io.open("logs/cloneimmune.txt", "w+")
  local m = "tImmune = { "
  for a, b in pairs(tImmune) do m = m..(string.format("[%q]=",a)..b..","); end
  m = m.." }"
  f:write( m ); f:flush(); f:close();
end

function NewUserConnected(curUser,sdata)
  _tIPStorage[curUser.sIP]=curUser.sName
end

function ChatArrival (user,data)
  if (user.bOperator) then
    local data = string.sub( data, 1, -2 )
    local s,e,cmd = string.find( data, "%b<>%s+([%-%+%?]%S+)" )
    if cmd then
      return Parse( user, cmd, data, false )
    end
  end
end

function ToArrival ( user, data )
  if ( user.bOperator ) then
    local data = string.sub( data , 1, -2 )
    local s,e, cmd = string.find( data , "%$%b<>%s+([%-%+%?]%S+)" )
    if cmd then
      return Parse ( user, cmd , data , true )
    end
  end
end

function UserDisconnected(user)
  if clonedout[user.sName] then
    if not GetItemByName(clonedout[user.sName]) then -- if the clone isn't online either, remove the ip only then
      tIPStorage[user.sIP]=nil
    else -- else the IP gets the value of the clone who is still online
      tIPStorage[user.sIP]=GetItemByName(clonedout[user.sName]).sName
    end
  else -- normal disconnection
    tIPStorage[user.sIP]=nil
  end
end

function Parse( user, cmd, data, how )
  local function SendBack( user, msg , from, how )
    if how then user:SendPM( from or Bot , msg );return 1; end;
    user:SendData( from or Bot, msg );return 1;
  end
  local t = {
  --- Add to cloneList
  ["+clone"] = function ( user , data , how )
    local s,e, name = string.find( data, "%b<>%s+%S+%s+(%S+)" )
    if not name then user:SendData(Bot, "*** Error: Type +clone nick") end
    if tImmune[name] then user:SendData("nope") end
    local nick = GetItemByName(name)
    if not nick then user:SendData(Bot, "*** Error: User is not online.") end
    tImmune[name] = 1
    OnExit()
    user:SendData(Bot, name.." is now immune to clone checks!")
    return 1
  end ,
  --- Remove from cloneList
  ["-clone"] = function ( user , data , how )
    local s,e, name = string.find(data, "%b<>%s+%S+%s+(%S+)")
    if not name then user:SendData(Bot, "*** Error: Type -clone nick") end
    if not tImmune[name] then user:SendData(Bot,"The user "..name.." is not immune!")  end
    local nick = GetItemByName( name )
    if not nick then user:SendData(Bot, "*** Error: That user is not online.") end
    tImmune[name] = nil
    OnExit()
    user:SendData(Bot,"Now "..name.." is not no longer immune to clone checks!")
    return 1
  end,
  --- Show cloneList
  ["?clone"] = function ( user , data, how )
    local m = ""
    for nick, _ in pairs(tImmune) do
    local s = "Offline"
    if GetItemByName(nick) then s = "Online" end
    m = m.."\r\n\t  • ("..s..")  "..nick
    end
    if m == "" then return SendBack( user, "There are no users that can have a clone", Bot, how ) end
    m = "\r\nThe following users can have clones in this hub:"..m
    return SendBack( user, m , Bot, how )
  end,
  --- Show cloneBot help
  ["?clonehelp"] = function ( user, data , how )
    local m = "\r\n\r\nHere are the commands for the CloneBot:"..
    "\r\n\t+clone \t allows to have a clone"..
    "\r\n\t-clone \t removes from the clone list"..
    "\r\n\t?clone\t\t shows the users allowed to have a clone"..
    "\r\n\t?clonehelp \t allows to have a clone"
    return SendBack( user, m, Bot, how )
  end, }
  if t[cmd] then return t[cmd]( user, data, how ) end
end