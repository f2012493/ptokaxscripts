-- PostMan by bastya_elvtars (the rock n' roll doctor), Herodes and Skippy84
-- offline message system
-- original code ripped from LawMaker
-- comands can be PMed or typed in main, the bot responds to them according to the environment (sometimes at least :D)
-- the commands are case insensitive, the parameters aren't :)
-- The code is licensed under the Microsoft Reciprocal License (Ms-RL). See postman/LICENSE for details.

--------------------------------SETTINGS----------------------------------------

Bot = {
name = "PostMan" , -- bot's name
email = "postman@mail.me", -- bot's email
desc = "Post messages to other users here..", -- bot's desc
}
inboxsize=10 -- the maximum amount of messages users can have in their inbox

mass_max_users=5 -- When sending a mass offline mail, how many recipients may be specified at once?

-- Where should the 'new message' alert appear? If true then PM, if false then main.
newalertPM=false

cmdpost = "postmsg" -- Post
cmdmass = "masspost" -- Mass post, i. e. post the same message to more recipients
cmdread = "readmsg" -- Read
cmdibox = "inbox" -- Inbox
cmddbox = "delmsg" -- Delete

----------------------END OF SETTINGS-------------------------------------------

-- Load the base64 library (argh I keep wondering why package.cpath is the Px folder, but I live with it)
require "scripts.postman.base64"
require "scripts.postman.tables"
-------------------------------------- Utility Functions

function cls()
    collectgarbage("collect")
    io.flush()
end

function OnStartup()
  SetMan.SetBool(55, true)
  local function load() -- Load the list of guys that have visited the hub
    local t = {}; local f = io.open(Core.GetPtokaXPath().."scripts/postman/washere.lst", "r")
    if f then for l in f:lines() do t[l] = 1; end; f:close(); end
    return t;
  end
  washere = load()
  setmetatable(washere,
  {
    __newindex=function(tbl, key, val)
      local f = io.open( Core.GetPtokaXPath().."scripts/postman/washere.lst", "a+")
      f:write(key)
      f:close()
      rawset (tbl, key, val)
    end
  })
  local f = io.open(Core.GetPtokaXPath().."scripts/postman/washere.lst", "w+") -- Because the file grew huge with appends, shrink it.
  for k in pairs( washere ) do
    f:write(k)
  end
  f:close()
  message = {}
	if loadfile(Core.GetPtokaXPath().."scripts/postman/offline.dat") then -- Is the offline.dat proper lua?
		message=table.load(Core.GetPtokaXPath().."scripts/postman/offline.dat") -- Ok, then chill loads 
	else -- replace corrupted offline.dat
		table.save(message,Core.GetPtokaXPath().."scripts/postman/offline.dat")
	end
  Core.RegBot(Bot.name, Bot.desc, Bot.email, true)
end

  -------------------------------------- Command Functions
  --- post msg
function postmsg( user, data, how )
  local nick,msg = data:match("(%S+)%s+(.+)")
  if nick then
    checknsend (user,nick,msg)
  else
    SendBack( user, "Bad syntax! Usage: !"..cmdpost.." <nick> <message>", Bot.name, how )
  end
  cls(); return true;
end

function checknsend (user,nick,msg)
  nick=nick:lower()
  if not Core.GetUser(nick) then
    if washere[nick] then
      local function checksize(n) local cnt = 0; for a,b in pairs(message[n]) do cnt = cnt + 1; end return cnt; end
      message[nick] = message[nick] or {}
      if (checksize(nick) < inboxsize) then
        table.insert( message[nick], { ["message"] = base64.enc(msg), ["who"] = base64.enc(user.sNick), ["when"] = os.date("%Y. %m. %d. %X"), ["read"] = 0, } )
        SendBack( user, "Successfully sent the message!", Bot.name, how )
        table.save(message,Core.GetPtokaXPath().."scripts/postman/offline.dat")
      else
        SendBack( user, "Sorry, but "..nick.." has a full inbox. Try again later.", Bot.name, how )
      end
    else
      SendBack( user, "User "..nick.." has never been in the hub.", Bot.name, how )
    end
  else
    SendBack( user, nick.." is online! PM would be simpler in this case...", Bot.name, how )
  end
end

function masspost ( user, data, how)
  local nicks,msg=data:match("([^%$]+)%$(.+)")
  if nicks then
    local _,no_args = string.gsub(nicks,"(%S+)","")
    if no_args > mass_max_users then
      SendBack( user, "Too many nicks specified, maximum number of nicks you can specify is "..mass_max_users.." and you specified "..no_args..".", Bot.name, how )
      return
    end
    for nick in string.gmatch(nicks,"(%S+)") do
      checknsend (user,nick:lower(),msg)
    end
  end
end

function delmsg( user, data, how )
  local nick=user.sNick:lower()
  if message[nick] then
    if data then
      local function checksize(n) local cnt = 0; for a,b in pairs(message[n]) do cnt = cnt + 1; end return cnt; end
      local function resort(t) local r ={}; for i,v in pairs(t) do table.insert(r, v); end; return r; end
      local bDeleted=false
      for num in data:gmatch( "(%d+)" ) do
        num = tonumber(num);
        if message[nick][num] then
          message[nick][num] = nil
          SendBack( user, "Message #"..num.." has been successfully deleted!", Bot.name, how )
          bDeleted=true
        else
          SendBack( user, "Message #"..num.." does not exist!", Bot.name, how )
        end
      end
      message[nick] = resort(message[nick]);
      if checksize(nick) == 0 then message[nick] = nil; end
      if bDeleted then table.save(message,Core.GetPtokaXPath().."scripts/postman/offline.dat") end
    else
      SendBack( user, "Bad syntax! Usage: !"..cmddbox.." <msgnumber>. Multiple numbers can be added separated by spaces.", Bot.name, how )
    end
  else
    SendBack( user, "Your inbox is empty.", Bot.name, how )
  end
  cls(); return true;
end

    ----------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------- show inbox
function inbox( user, how )
  local nick=user.sNick:lower()
  local sep, msg = ( "="):rep( 75 ), "\r\n\r\n\t\t\t\t\t\t\tHere is your inbox:\r\n"
  msg = msg..sep.."\r\n Msg#\tSender\tTime of sending\t\tRead\r\n"..sep
  if message[nick] then
    local function numess ( r ) if r == 0 then return "no"; end return "yes"; end
    local function checksize ( n ) local cnt = 0; for a,b in pairs(message[n]) do cnt = cnt + 1; end return cnt; end
    for num, t in pairs(message[nick]) do
      msg=msg.."\r\n "..num.."\t"..base64.dec(t.who).."\t"..t.when.."\t"..numess(t.read).."\r\n"..sep
    end
    SendBack( user, msg, Bot.name, true )
    SendBack( user, "Type !"..cmdread.." <number> too see an individual message. Multiple numbers can be added separated by spaces.", Bot.name, true )
    if checksize(nick) >= inboxsize then SendBack( user, "Alert: Your inbox is full!", Bot.name, true ); end
  else
    SendBack( user, "You have no messages.", Bot.name, how )
  end
  cls(); return true;
end

    --- read msg(s)
function readmsg( user, data, how )
  local nick=user.sNick:lower()
  if message[nick] then
    if data then
      for num in data:gmatch(  "(%d+)" ) do
        if num then num = tonumber(num) end
        if num and message[nick][num] then
          local t = message[nick][num]
          local msg, sep, set = "\r\n\r\n\t\t\t\t\t\t\tMessage #"..num.."\r\n", ("="):rep( 30 ), ("- "):rep(20)
          msg = msg..sep.."\r\n\r\nFrom: "..base64.dec(t.who).."\tTime: "..t.when.."\t\tMessage follows\r\n"..set.."[Message start]\r\n"..base64.dec(t.message).."\r\n"..set.."[Message end]\r\n"..sep
          SendBack( user, msg, Bot.name, true )
          if t.read == 0 then t.read = 1; table.save(message,Core.GetPtokaXPath().."scripts/postman/offline.dat"); end
        else
          SendBack( user, "Message #"..num.." does not exist!", Bot.name, how )
        end
      end
    else
      SendBack( user, "Bad syntax! Usage: !"..cmdread.." <msgnumber>. Multiple numbers can be added separated by spaces.", Bot.name, how )
    end
  else
    SendBack( user, "Your inbox is empty.", Bot.name, how )
  end
  cls(); return true;
end

function SendBack( user, msg, who, pm )
  if pm then Core.SendPmToUser ( user, who, msg ); else Core.SendToUser( user, "<"..who.."> "..msg ); end
end

function UserConnected(user)
  local nick=user.sNick:lower()
  local RC={"$UserCommand 1 3 :PostMan:\\INBOX$<%[mynick]> !"..cmdibox.."&#124;","$UserCommand 1 3 :PostMan:\\Post a Message$<%[mynick]> !"..cmdpost.." %[line:Target user:] %[line:Message:]&#124;",
  "$UserCommand 1 3 :PostMan:\\Read a Message$<%[mynick]> !"..cmdread.." %[line:Enter Nr(s) of Post(s) you would like to read:]&#124;",
  "$UserCommand 1 3 :PostMan:\\Delete a Message$<%[mynick]> !"..cmddbox.." %[line:Enter Nr(s) of Post(s) you would like to delete:]&#124;",
  "$UserCommand 1 3 :PostMan:\\Post the same message to more users$<%[mynick]> !"..cmdmass.." %[line:Enter usernames separated by spaces:] $%[line:Enter the message:]&#124;"}
  Core.SendToUser(user, table.concat(RC,"|"))
  Core.SendToUser(user, "<"..Bot.name.."> ".."New Right-Click for Postman is Available..")
  washere[nick] = 1
  if message[nick] then
    local cnt=0
    for a,b in pairs(message[nick]) do if (b.read == 0) then cnt = cnt+1; end end
    if (cnt > 0) then SendBack( user, "You have "..cnt.." new messages. Type !"..cmdibox.." to see your inbox!", Bot.name, newalertPM ); end
  end
end
RegConnected = UserConnected
OpConnected = UserConnected

function ChatArrival(user,data)
  local cmd = data:match("^%b<>%s+[%!%+%#%?%-](%S+).*%|$")
  if cmd then return parsecmds( user, data, cmd:lower() ); end
end

function ToArrival(user,data)
  local cmd = data:match("^$To:%s+%S+%s+From:%s+%S+%s+$%b<>%s+[%!%+%#%?%-](%S+)%s*.*%|$")
  if cmd then return parsecmds( user, data, cmd:lower(), true ) end
end

function parsecmds( user, data, cmd, how )
  if not how then
    data = data:match("^%b<>%s+[%!%+%#%?%-]%S+(.+)%|$")
  else
    data = data:match("^$To:%s+%S+%s+From:%s+%S+%s+$%b<>%s+[%!%+%#%?%-]%S+%s*(.*)%|$")
  end
  local t = {
    [cmdpost] = { postmsg, { user, data, how } },
    [cmdread] = { readmsg, { user, data, how } },
    [cmdibox] = { inbox, { user, how } },
    [cmddbox] = { delmsg, { user, data, how } },
    [cmdmass] = { masspost, { user, data, how } },
    }
  local c=t[cmd]
  if c then
    c[1]( unpack(c[2]))
    return true
  end
end

-- OnError = Core.SendToOps

function OnError (err)
  Core.SendToOps (err)
end

function UserDisconnected(user)
  local nick=user.sNick:lower()
  washere[nick] = 1
end

RegDisconnected = UserDisconnected
OpDisconnected=UserDisconnected
