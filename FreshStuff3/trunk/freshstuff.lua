--[[
FreshStuff3 v5
This is the common script that gets loaded by host apps, then takes care of everything else :-D
Characteristics (well, proposed - no, they are almost real as of end-feb 2007): modular and portable among host programs
Distributed under the terms of the Common Development and Distribution License (CDDL) Version 1.0. See docs/license.txt for details.
]]
AllStuff,NewestStuff,Engine,Bot,Commands,Levels = {},{},{},{},{},{}
Bot.version="FreshStuff3 5.5 alpha 1"
ModulesLoaded = {}

do -- detect the host app
-- This is done by detecting global tables that are specific to the host app.
local Host=
  {
--     ["DC"]="bcdc",
--     ["VH"]="verli",
    ["Core"] = {func = "GetPtokaXPath", path = "scripts/freshstuff/?.lua", mod = "ptokax"},
  }

local c
  for glob, loader in pairs(Host) do
    if _G[glob] then
      if loader.param then
        package.path = _G[glob][loader.func](_G[loader.param])..loader.path
      else
        package.path = _G[glob][loader.func]()..loader.path
      end
      require (loader.mod)
      c = true
      break
    end
  end
  assert(c,"FATAL: This script does not support your host application. :-(")
end

require "tables"
require "kernel"

local hostloader =
  {
    ["ptokax"] =
      function()
        package.cpath = Core.GetPtokaXPath().."scripts/freshstuff/lib/?.dll"
        require "pxlfs"
        package.path = Core.GetPtokaXPath().."scripts/freshstuff/components/?.lua"
        for entry in lfs.dir( Core.GetPtokaXPath().."scripts/freshstuff/components" ) do
          local filename, ext = entry:match("([^%.]+)%.lua$")
          if filename then require (filename) end
        end
      end,
  }

for k,v in pairs(hostloader) do
  if package.loaded[k] then v() break end
end

Functions={}
