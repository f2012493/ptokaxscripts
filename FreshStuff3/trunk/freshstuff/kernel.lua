-- Core module for FreshStuff3 v5 by bastya_elvtars
-- License: GNU GPL v2
-- This module contains functions that generate the required messages, save/load releases etc.

do
  setmetatable (Engine,_Engine)
  Engine[Commands.Show]=
    {
      function (user,data)
        if Count < 1 then return "There are no releases yet, please check back soon.",1 end
        local cat= string.match(data, "%b<>%s+%S+%s+(%S+)")
        local latest=string.match(data, "%b<>%s+%S+%s+%S+%s+(%d+)")
        if not cat then
          return MsgAll,1
        else
          if cat == "new" then
            return MsgNew,1
          elseif Types[cat] then
            if latest then
              return ShowRelNum(cat,latest),1
            else
              return ShowRelType(cat),1
            end
          else
            return "No such type.",1 
            -- ret. vals: 1: sendtxt (on env/PM only in BCDC), 2: PM only (same in BCDC), 3: to ops (N/A in BCDC, maybe DC():PrintDebug, or hub:injectChat?), 4: to all (BCDC: hub:sendChat)
          end
        end
      end,
      {},Levels.Show,"<type>\t\t\t\t\tShows the releases of the given type, with no type specified, shows all." 
    }
  Engine[Commands.Add]=
    {
      function (user,data)
        local nick
        if hostprg==1 then nick=user.sName end
        local cat,tune= string.match(data, "%b<>%s+%S+%s+(%S+)%s+(.+)")
        if cat then
          if Types[cat] then
            if string.find(tune,"$",1,true) then return "The release name must NOT contain any dollar signs ($)!" end
            if Count > 0 then
              for i=1, Count do
                local ct,who,when,title=unpack(AllStuff[i])
                if title==tune then
                  return "The release is already added under category "..Types[ct].."."
                end
              end
            end
            Count = Count + 1
            AllStuff[Count]={cat,nick,os.date("%m/%d/%Y"),tune}
            SaveRel()
            ReloadRel()
            OnRelAdded(user,data,cat,tune)
          else
            return "Unknown category: "..cat,1
          end
        else
          return "yea right, like i know what you got 2 add when you don't tell me!",1
        end
      end,
      {},Levels.Add,"<type> <name>\t\t\t\tAdd release of given type."
    }
  Engine[Commands.Delete]=
    {
      function (user,data)
        local _,_,what=string.find(data,"%b<>%s+%S+%s+(.+)")
        if what then
          local cnt,x=0,os.clock()
          local tmp={}
          for w in string.gmatch(what,"(%d+)") do
            table.insert(tmp,tonumber(w))
          end
          table.sort(tmp)
          local msg="\r\n"
          for k=#tmp,1,-1 do
            local n=tmp[k]
            if AllStuff[n] then
              msg=msg.."\r\n"..AllStuff[n][4].." is deleted from the releases."
              AllStuff[n]=nil
              cnt=cnt+1
            else
              msg=msg.."\r\nRelease numbered "..n.." wasn't found in the releases."
            end
          end
          if cnt>0 then
            SaveRel()
            ReloadRel()
            msg=msg.."\r\n\r\nDeletion of "..cnt.." item(s) took "..os.clock()-x.." seconds."
          end
          return msg,1
        else
          return "yea right, like i know what i got 2 delete when you don't tell me!.",1
        end
      end,
      {},Levels.Delete,"<ID>\t\t\t\t\tDeletes the releases of the given ID, or deletes multiple ones if given like: 1,5,33,6789"
    }
  Engine[Commands.AddCatgry]=
    {
      function (user,data)
        local what1,what2=string.match(data,"%b<>%s+%S+%s+(%S+)%s+(.+)")
        if what1 then
          if string.find(what1,"$",1,true) then return "The dollar sign is not allowed.",1 end
          if not Types[what1] then
            Types[what1]=what2
            SaveCt()
            return "The category "..what1.." has successfully been added.", 1
          else
            if Types[what1]==what2 then
              return "Already having the type "..what1
            else
              Types[what1]=what2
              SaveCt()
              return "The category "..what1.." has successfully been changed.",1
            end
          end
        else
          return "Category should be added properly: +"..Commands.AddCatgry.." <category_name> <displayed_name>", 1
        end
      end,
      {},Levels.AddCatgry,"<new_cat> <displayed_name>\t\t\tAdds a new release category, displayed_name is shown when listed."
    }
  Engine[Commands.DelCatgry]=
    {  
      function (user,data)
        local what=string.match(data,"%b<>%s+%S+%s+(%S+)")
        if what then
          if not Types[what] then
            return "The category "..what.." does not exist.",1
          else
            Types[what]=nil
            SaveCt()
            return "The category "..what.." has successfully been deleted.",1
          end
        else
          return "Category should be deleted properly: +"..Commands.DelCatgry.." <category_name>",1
        end
      end,
      {},Levels.DelCatgry,"<cat>\t\t\t\t\tDeletes the given release category.."
    }
  Engine[Commands.ShowCtgrs]=
    {
      function (user,data)
        local msg="\r\n======================\r\nAvilable categories:\r\n======================\r\n"
        for a,b in pairs(Types) do
          msg=msg.."\r\n"..a
        end
        return msg,2
      end,
      {},Levels.ShowCtgrs,"\t\t\t\t\tShows the available release categories."
    }
  Engine[Commands.Search]=
    {
      function (user,data)
        local what=string.match(data,"%b<>%s+%S+%s+(.+)")
        if what then
          local res,rest=0,{}
          local msg="\r\n---------- You searched for keyword \""..what.."\". The results: ----------\r\n\r\n"
          for a,b in ipairs(AllStuff) do
            if string.find(string.lower(b[4]),string.lower(what),1,true) then
              table.insert(rest,{b[1],b[2],b[3],b[4],a})
            end
          end
          if #rest~=0 then
            for idx,tab in ipairs(rest) do
            local _type,who,when,title,id=unpack(tab)
            res= res + 1
            msg = msg.."ID: "..id.."\t"..title.." // (Added by "..who.." at "..when..")\r\n"
            end
            msg=msg.."\r\n"..string.rep("-",20).."\r\n"..res.." results."
          else
            msg=msg.."\r\nSearch string "..what.." was not found in releases database."
          end
          return msg,2
        else
          return "yea right, like i know what you got 2 search when you don't tell me!",1
        end
      end,
      {},Levels.Search,"<string>\t\t\t\t\tSearches for release NAMES containing the given string."
    }
  Engine[Commands.ReLoad]=
    {
      function(user)
        local x=os.clock()
        OpenRel()
        ShowRel(NewestStuff)
        ShowRel(AllStuff)
        return "Releases reloaded, took "..os.clock()-x.." seconds.",1
      end,
      {},Levels.ReLoad,"\t\t\t\t\t\tReloads the releases database."
    }
  Engine[Commands.Help]=
    {
      function (user,data,env)
        local count=0
        local hlptbl={}
        local hlp="\r\nCommands available to you are:\r\n=================================================================================================================================\r\n"
        for a,b in pairs(commandtable) do
          if b["level"]~=0 then
            if userlevels[user.iProfile] >= b["level"] then
              count=count+1
              table.insert(hlptbl,"!"..a.." "..b["help"])
            end
          end
        end
        table.sort(hlptbl)
        hlp=hlp..table.concat(hlptbl,"\r\n").."\r\n\r\nAll the "..count.." commands you can use can be typed in main or in PM session with anyone, and the available prefixes are:"..
        " ! # + - ?\r\n=================================================================================================================================\r\n"..Bot.version
        return hlp,2
      end,
      {},1,"\t\t\t\t\t\tShows the text you are looking at."
    }
end

function OpenRel()
	AllStuff,NewestStuff,TopAdders = nil,nil,nil
	collectgarbage(); io.flush()
	AllStuff,NewestStuff,TopAdders = {},{},{}
	Count,Count2 = 0,0
	local f=io.open("freshstuff/data/releases.dat","r")
	if f then
  for line in f:lines() do
    local cat,who,when,title=string.match(line, "(.+)$(.+)$(.+)$(.+)")
    if cat then
			if TopAdders[who] then TopAdders[who] = TopAdders[who]+1 else TopAdders[who]=1 end
			 if string.find(when,"%d+/%d+/0%d") then -- compatibility with old file format
					local m,d,y=string.match(when,"(%d+)/(%d+)/(0%d)")
					when=m.."/"..d.."/".."20"..y
			 end
				Count = Count +1
				AllStuff[Count]={cat,who,when,title}
			else
				return "Releases file is corrupt, failed to load all items."
			end
		end
  	f:close()
	end
	if Count > MaxNew then
		local tmp = Count - MaxNew
		Count2=(Count - MaxNew)
		for i = tmp, Count do
			Count2=Count2 + 1
			if AllStuff[Count2] then
				NewestStuff[Count2]=AllStuff[Count2]
			end
		end
	else
		for i=1, Count do
			Count2 = Count2
				if AllStuff[i] then
					NewestStuff[Count2]=AllStuff[i]
				end
			end
	end
end

function ShowRel(tab)
  local Msg = "\r\n"
  local cat,who,when,title
  local tmptbl={}
  local cunt=0
  if tab == NewestStuff then
    if Count2 == 0 then
      MsgNew = "\r\n\r\n".." --------- The Latest Releases -------- \r\n\r\n  No releases on the list yet\r\n\r\n --------- The Latest Releases -------- \r\n\r\n"
    else
      for i=1, Count2 do
	if NewestStuff[i] then
	  cat,who,when,title=unpack(NewestStuff[i])
	  if title then
	    if Types[cat] then cat=Types[cat] end
	    if not tmptbl[cat] then tmptbl[cat]={} end
	    table.insert(tmptbl[cat],Msg.."ID: "..i.."\t"..title.." // (Added by "..who.." at "..when..")")
            cunt=cunt+1
	  end
	end
      end
    end
    for a,b in pairs (tmptbl) do
      Msg=Msg.."\r\n"..a.."\r\n"..string.rep("-",33).."\r\n"..table.concat(b).."\r\n"
    end
    local new=MaxNew if cunt < MaxNew then new=cunt end
    MsgNew = "\r\n\r\n".." --------- The Latest "..new.." Releases -------- "..Msg.."\r\n\ --------- The Latest "..new.."  Releases -------- \r\n\r\n"
  else
    if Count == 0 then
      MsgAll = "\r\n\r\r\n".." --------- All The Releases -------- \r\n\r\n  No releases on the list yet\r\n\r\n --------- All The Releases -------- \r\n\r\n"
    else
      MsgHelp  = "  use "..Commands.Show.." <new>"
      for a,b in pairs(Types) do
	      MsgHelp  = MsgHelp .."/"..a
      end
      MsgHelp  = MsgHelp .."> to see only the selected types"
      for i=1, Count do
	if AllStuff[i] then
	  cat,who,when,title=unpack(AllStuff[i])
	  if title then
	    if Types[cat] then cat=Types[cat] end
	    if not tmptbl[cat] then tmptbl[cat]={} end
	    table.insert(tmptbl[cat],Msg.."ID: "..i.."\t"..title.." // (Added by "..who.." at "..when..")")
	  end
	end
      end
      for a,b in pairs (tmptbl) do
	Msg=Msg.."\r\n"..a.."\r\n"..string.rep("-",33).."\r\n"..table.concat(b).."\r\n"
      end
      MsgAll = "\r\n\r\r\n".." --------- All The Releases -------- "..Msg.."\r\n --------- All The Releases -------- \r\n"..MsgHelp .."\r\n"
    end
  end
end

function ShowRelType(what)
  local cat,who,when,title
  local Msg,MsgType,tmp = "\r\n",nil,0
  if Count == 0 then
    MsgType = "\r\n\r\n".." --------- All The "..Types[what].." -------- \r\n\r\n  No "..string.lower(Types[what]).." yet\r\n\r\n --------- All The "..Types[what].." -------- \r\n\r\n"
  else
    for i=1, Count do
      cat,who,when,title=unpack(AllStuff[i])
      if cat == what then
	tmp = tmp + 1
	Msg = Msg.."ID: "..i.."\t"..title.." // (Added by "..who.." at "..when..")\r\n"
      end
    end
    if tmp == 0 then
      MsgType = "\r\n\r\n".." --------- All The "..Types[what].." -------- \r\n\r\n  No "..string.lower(Types[what]).." yet\r\n\r\n --------- All The "..Types[what].." -------- \r\n\r\n"
    else
      MsgType= "\r\n\r\n".." --------- All The "..Types[what].." -------- \r\n"..Msg.."\r\n --------- All The "..Types[what].." -------- \r\n\r\n"
    end
  end
  return MsgType
end

function ShowRelNum(what,num) -- to show numbers of categories
  num=tonumber(num)
  local Msg="\r\n"
  local cunt=0
  local target=Count+1
  local cat,who,when,title
  if num > Count then num=Count end
  for t=1,num do
		target=target-1
    if AllStuff[target] then
      cat,who,when,title=unpack(AllStuff[target])
      Msg = Msg.."ID: "..target.."\t"..title.." // (Added by "..who.." at "..when..")\r\n"
      cunt=cunt+1
    else
      break
    end
  end
  if cunt < num then num=cunt end
  local MsgType = "\r\n\r\n".." --------- The Latest "..num.." "..Types[what].." -------- \r\n\r\n"..Msg.."\r\n\r\n --------- The Latest "..num.." "..Types[what].." -------- \r\n\r\n"
  return MsgType
end

function SaveRel()
  local f= io.open("freshstuff/data/releases.dat","w+")
  for i=1,Count do
    if AllStuff[i] then
      f:write(table.concat(AllStuff[i],"$").."\n")
    end
  end
  f:flush()
  f:close()
end

function ReloadRel(user,data,env)
  OpenRel()
  ShowRel(NewestStuff)
  ShowRel(AllStuff)
end

function SaveCt()
  local f=io.open("freshstuff/data/categories.dat","w+")
  f:write("Types={\n")
  for a,b in pairs(Types) do
    f:write("[\""..a.."\"]=\""..b.."\",\n")
  end
  f:write("}")
  f:close()
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

SendToAll("*** "..botver.." kernel loaded.")