-- FreshStuff3 v5
-- Embryonic pre-alpha version
-- License: GNU GPL v2
-- This is the common script that gets loaded by host apps, then takes care of everything else :-D
-- Characteristics (well, proposed): modular and portable among host programs

--------
-- TODO:
--------
  -- make command registration & rightclick registration use metatables,
                -- thus functions & commands belonging to them can be fusioned
                -- the whole thingy becomes more reliable
                -- loads of code can be removed
                -- faster startup is also expectable (I will not benchmark)
  -- make script decide whether to register rightclicks or not (BCDC++ issue mainly) - this is easy, just need to (not) register this on host-spec. mods
  -- make the script fully portable, i. e. it can use all stuff from the host program, while it interoperates with it smoothly (especially data sending)
                -- this involves calling freshstuff-related events in script-specific modules as well wherever appropriate
                -- OR return in a way that can easily be parsed and data can be sent appropriately (looks better) // and has been chosen
  -- make the script automatically detect the environment
                -- (not hard, just need to look for global variables that are specific to each host program, like VH, frmHub or DC, it is unlikely that users will declare it themselves :-D)

hostprg=1

--<SettingsStart>
Bot = {
        name="post-it_memo",
        email="bastyaelvtars@gmail.com",
        desc="Release bot",
        version="5.0 pre-alpha",
      } -- Set the bot's data.
    ProfilesUsed= 0 -- 0 for lawmaker/terminator (standard), 1 for robocop, 2 for psyguard
    Commands={
      Add="addrel", -- Add a new release
      Show="releases", -- This command shows the stuff, syntax : +albums with options new/game/warez/music/movie
      Delete="delrel", -- This command deletes an entry, syntax : +delalbum THESTUFF2DELETE
      ReLoad="reloadrel", -- This command reloads the txt file. syntax : +reloadalbums (this command is needed if you manualy edit the text file)
      Search="searchrel", -- This is for searching inside releases.
      AddCatgry="addcat", -- For adding a category
      DelCatgry="delcat", -- For deleting a category
      ShowCtgrs="showcats", -- For showing categories
      Prune="prunerel", -- Pruning releases (removing old entries)
      TopAdders="topadders", -- Showing top adders
      Help="relhelp", -- Guess what! :P
      AddReq="addreq",
      ShowReqs="showreqs",
    } -- No prefix for commands! It is automatically added. (<--- multiple prefixes)
    Levels={
      Add=4, -- adding
      Show=1, -- showing all
      Delete=4,   -- deleting
      ReLoad=4,   -- reload
      Search=1, -- search
      AddCatgry=4, -- add category
      DelCatgry=4, -- delete category
      ShowCtgrs=1, -- show categories
      Prune=5, -- prune (delete old)
      TopAdders=1, -- top release adders
      Help=1, -- Guess what! :P
      AddReq=1,
      ShowReqs=1,
    } -- You set the userlevels according to... you know what :P
    MaxItemAge=30 --IN DAYS
    TopAddersCount=5 -- shows top-adders on command, this is the number how many it should show
    ShowOnEntry = 2 -- Show latest stuff on entry 1=PM, 2=mainchat, 0=no
    MaxNew = 20 -- Max stuff shown on newalbums/entry
    WhenAndWhatToShow={
      ["20:47"]="music",
      ["20:48"]="warez",
      ["20:49"]="new",
      ["20:50"]="all",
      ["23:44"]="new",
    }-- Timed release announcing. You can specify a category name, or "all" or "new"
--<SettingsEnd>

Host={"ptokax","bcdc","verli","aquila"}
AllStuff,NewestStuff,rightclick,commandtable,rctosend,Engine={},{},{},{},{},{}
botver="FreshStuff3 v 5.0 alpha1"
package.path="freshstuff/?.lua"
require(Host[hostprg])
require("kernel")
package.path="freshstuff/components/?.lua"
require("extras")
require("requester")

Functions={}