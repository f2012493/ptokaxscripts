-- PostMan by bastya_elvtars (the rock n' roll doctor), Herodes and Skippy84
-- offline message system
-- original code ripped from LawMaker
-- comands can be PMed or typed in main, the bot responds to them according to the environment (sometimes at least :D)
-- the commands are case insensitive, the parameters aren't :)

------- 0.2:
-- added a function so ppl cannot post 2 online users

------- 0.3:
-- converted to lua5
-- washere is now global, no more CPU spikes

------- 0.4:
-- touched by Herodes (optimisation tsunami)
-- added : more details on the bot
-- added : message privacy ;)
-- changed : better way to parseenv ;)
-- changed : better way to display messages and inbox
-- changed : better way to parsecmds ( thx bastya_elvtars ;)

------- 0.5:
-- touched by Skippy84
-- fix error: make offline.dat thx goto Herodes for the idea to fix the problem
-- fix error: false command !showmsg
-- added: commands can edit at the Settings section
-- added: shown commands linked to the editable commands (so ther change on the fly)

------- 0.51:
-- bastya_elvtars put his hands back on this
-- script now creates an empty offline.dat if does not exist... you guys keep ignoring new Lua5 features :P
-- thx guys for the features you added, they are really eye-candy

------- 0.6:
-- touched again by Skippy84
-- added: a little rightclick menu

------- 0.7:
--[[
changed: Lua 5.1 and related optimizations (bastya_elvtars)
added: message encoding done by base64 encoder/decoder (c) 2006 by Alex Kloss
                                                      (http://lua-users.org/wiki/BaseSixtyFour) - sorry Herodes
changed: messages are encoded upon sending, thus we prevent decoding/encoding flaws when user comes
                                                      online before the first script restart
fixed: corrected some rightclick typos, lingos and made message sending through rightclick a bit more 'intelligent'
changed: created a separate postman folder, not to pollute the scripts dir with washere.lst and offline.dat
added: option for new message alert (PM or main)
]]
------- 0.8:
--[[
added: mass offline message. Usage: !masspost nick1 nick2 nick3 $message // The trailing dollar sign is important!!!
added: case insensivity for nicks
changed: using chill's extremely handy table.save and table.load routines
changed: checknsend is a separate function for checking and sending
]]
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

function Main()
  local function load()
    local t = {}; local f = io.open("postman/washere.lst", "r")
    if f then for l in f:lines() do t[l] = 1; end; f:close(); end
    return t;
  end
  washere = load()
  message = {}
	if loadfile("postman/offline.dat") then
		message=table.load("postman/offline.dat")
	else -- replace corrupted offline.dat
		table.save(message,"postman/offline.dat")
	end
  frmHub:RegBot(Bot.name, 1, Bot.desc, Bot.email )
  Bot = Bot.name
end

  -------------------------------------- Command Functions
  --- post msg
function postmsg( user, data, how )
  local nick,msg = data:match("%b<>%s+%S+%s+(%S+)%s+(.+)")
  if nick then
    checknsend (user,nick,msg)
  else
    SendBack( user, "Bad syntax! Usage: !"..cmdpost.." <nick> <message>", Bot, how )
  end
  cls(); return 1;
end

function checknsend (user,nick,msg)
  nick=string.lower(nick)
  if not GetItemByName(nick) then
    if washere[nick] then
      local function checksize(n) local cnt = 0; for a,b in pairs(message[n]) do cnt = cnt + 1; end return cnt; end
      message[nick] = message[nick] or {}
      if (checksize(nick) < inboxsize) then
        table.insert( message[nick], { ["message"] = encode(msg), ["who"] = encode(user.sName), ["when"] = os.date("%Y. %m. %d. %X"), ["read"] = 0, } )
        SendBack( user, "Successfully sent the message!", Bot, how )
        table.save(message,"postman/offline.dat")
      else
        SendBack( user, "Sorry, but "..nick.." has a full inbox. Try again later.", Bot, how )
      end
    else
      SendBack( user, "User "..nick.." has never been in the hub.", Bot, how )
    end
  else
    SendBack( user, nick.." is online! PM would be simpler in this case...", Bot, how )
  end
end

function masspost ( user, data, how)
  local nicks,msg=data:match("%b<>%s+%S+%s+([^%$]+)%$(.+)")
  if nicks then
    local _,no_args = string.gsub(nicks,"(%S+)","")
    if no_args > mass_max_users then
      SendBack( user, "Too many nicks specified, maximum number of nicks you can specify is "..mass_max_users.." and you specified "..no_args..".", Bot, how )
      return
    end
    for nick in string.gmatch(nicks,"(%S+)") do
      checknsend (user,nick,msg)
    end
  end
end

function delmsg( user, data, how )
  if message[user.sName] then
    local args = data:match("%b<>%s+%S+%s+(.+)")
    if args then
      local function checksize(n) local cnt = 0; for a,b in pairs(message[n]) do cnt = cnt + 1; end return cnt; end
      local function resort(t) local r ={}; for i,v in pairs(t) do table.insert(r, v); end; return r; end
      local bDeleted=false
      for num in args:gmatch( "(%d+)" ) do
        num = tonumber(num);
        if message[user.sName][num] then
          message[user.sName][num] = nil
          SendBack( user, "Message #"..num.." has been successfully deleted!", Bot, how )
          bDeleted=true
        else
          SendBack( user, "Message #"..num.." does not exist!", Bot, how )
        end
      end
      message[user.sName] = resort(message[user.sName]);
      if checksize(user.sName) == 0 then message[user.sName] = nil; end
      if bDeleted then table.save(message,"postman/offline.dat") end
    else
      SendBack( user, "Bad syntax! Usage: !"..cmddbox.." <msgnumber>. Multiple numbers can be added separated by spaces.", Bot, how )
    end
  else
    SendBack( user, "Your inbox is empty.", Bot, how )
  end
  cls(); return 1;
end

    ----------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------- show inbox
function inbox( user, how )
  local sep, msg = ( "="):rep( 75 ), "\r\n\r\n\t\t\t\t\t\t\tHere is your inbox:\r\n"
  msg = msg..sep.."\r\n Msg#\tSender\tTime of sending\t\tRead\r\n"..sep
  if message[user.sName] then
    local function numess ( r ) if r == 0 then return "no"; end return "yes"; end
    local function checksize ( n ) local cnt = 0; for a,b in pairs(message[n]) do cnt = cnt + 1; end return cnt; end
    for num, t in pairs(message[user.sName]) do
      msg=msg.."\r\n "..num.."\t"..decode(t.who).."\t"..t.when.."\t"..numess(t.read).."\r\n"..sep
    end
    SendBack( user, msg, Bot, true )
    SendBack( user, "Type !"..cmdread.." <number> too see an individual message. Multiple numbers can be added separated by spaces.", Bot, true )
    if checksize(user.sName) >= inboxsize then SendBack( user, "Alert: Your inbox is full!", Bot, true ); end
  else
    SendBack( user, "You have no messages.", Bot, how )
  end
  cls(); return 1;
end

    --- read msg(s)
function readmsg( user, data, how )
  if message[user.sName] then
    local args=data:match("%b<>%s+%S+%s+(.+)")
    if args then
      for num in args:gmatch(  "(%d+)" ) do
        if num then num = tonumber(num) end
        if num and message[user.sName][num] then
          local t = message[user.sName][num]
          local msg, sep,set = "\r\n\r\n\t\t\t\t\t\t\tMessage #"..num.."\r\n", ("="):rep( 100 ), ("- "):rep(85)
          msg = msg..sep.."\r\n\r\nFrom: "..decode(t.who).."\tTime: "..t.when.."\t\tMessage follows\r\n"..set.."[Message start]\r\n"..decode(t.message).."\r\n"..set.."[Message end]\r\n"..sep
          SendBack( user, msg, Bot, true )
          if t.read == 0 then t.read = 1; table.save(message,"postman/offline.dat"); end
        else
          SendBack( user, "Message #"..num.." does not exist!", Bot, how )
        end
      end
    else
      SendBack( user, "Bad syntax! Usage: !"..cmdread.." <msgnumber>. Multiple numbers can be added separated by spaces.", Bot, how )
    end
  else
    SendBack( user, "Your inbox is empty.", Bot, how )
  end
  cls(); return 1;
end

function SendBack( user, msg, who, pm )
  if pm then user:SendPM ( who, msg ); else user:SendData( who, msg ); end
end

function NewUserConnected(user)
  local RC={"$UserCommand 1 3 :PostMan:\\INBOX$<%[mynick]> !inbox&#124;","$UserCommand 1 3 :PostMan:\\Post a Message$<%[mynick]> !postmsg %[line:Target user:] %[line:Message:]&#124;",
  "$UserCommand 1 3 :PostMan:\\Read a Message$<%[mynick]> !readmsg %[line:Enter Nr(s) of Post(s) you would like to read:]&#124;",
  "$UserCommand 1 3 :PostMan:\\Delete a Message$<%[mynick]> !delmsg %[line:Enter Nr(s) of Post(s) you would like to delete:]&#124;"}
  user:SendData(table.concat(RC,"|"))
  user:SendData(":PostMan:", "New Right-Click for Postman is Available..")
  if not washere[user.sName:lower()] then washere[user.sName:lower()] = 1 end
  if message[user.sName:lower()] then
    local cnt=0
    for a,b in pairs(message[user.sName:lower()]) do if (b.read == 0) then cnt = cnt+1; end end
    if (cnt > 0) then SendBack( user, "You have "..cnt.." new messages. Type !"..cmdibox.." to see your inbox!", Bot, newalertPM ); end
  end
end

function ChatArrival(user,data)
  local data = data:sub(1,-2)
  local cmd = data:match("%b<>%s+[!+.#?](%S+)")
  if cmd then return parsecmds( user, data, cmd:lower() ); end
end

function ToArrival(user,data)
  if (data:sub( 1, Bot:len()+5) == "$To: "..Bot) then
    local data = data:sub(1,-2)
    local cmd = data:match("%$%b<>%s+[!+.#?](%S+)")
    if cmd then return parsecmds( user, data, cmd:lower(), true ) end
    return 1
  end
end

function parsecmds( user, data, cmd, how )
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
    return 1
  end
end

function UserDisconnected(user)
  if not washere[user.sName:lower()] and user.bConnected then washere[user.sName:lower()] = 1; end
end

function OnExit()
    table.save(message,"postman/offline.dat")
    cls()
    local f = io.open( "postman/washere.lst", "w+")
    f:setvbuf("line")
    for a,b in pairs(washere) do f:write(a.."\n"); end
    f:close()
end

OpDisconnected=UserDisconnected
OpConnected=NewUserConnected