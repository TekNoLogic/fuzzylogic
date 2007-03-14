--[[-------------------------------------------------------------------------
  Copyright (c) 2006-2007, Dongle Development Team
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials provided
        with the distribution.
      * Neither the name of the Dongle Development Team nor the names of
        its contributors may be used to endorse or promote products derived
        from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------]]
local major = "DongleStub-Beta0"
local minor = tonumber(string.match("$Revision: 221 $", "(%d+)") or 1)

local g = getfenv(0)

if not g.DongleStub or g.DongleStub:IsNewerVersion(major, minor) then
	local lib = setmetatable({}, {
		__call = function(t,k) 
			if type(t.versions) == "table" and t.versions[k] then 
				return t.versions[k].instance
			else
				error("Cannot find a library with name '"..tostring(k).."'", 2)
			end
		end
	})

	function lib:IsNewerVersion(major, minor)
		local versionData = self.versions and self.versions[major]
		
		if not versionData then return true end
		local oldmajor,oldminor = versionData.instance:GetVersion()
		
		return minor > oldminor
	end
	
	local function NilCopyTable(src, dest)
		for k,v in pairs(dest) do dest[k] = nil end
		for k,v in pairs(src) do dest[k] = v end
	end

	function lib:Register(newInstance, activate, deactivate)
		local major,minor = newInstance:GetVersion()
		if not self:IsNewerVersion(major, minor) then return false end
		if not self.versions then self.versions = {} end

		local versionData = self.versions[major]
		if not versionData then
			-- New major version
			versionData = {
				["instance"] = newInstance,
				["deactivate"] = deactivate,
			}
			
			self.versions[major] = versionData
			if type(activate) == "function" then
				activate(newInstance)
			end
			return newInstance
		end
		
		local oldDeactivate = versionData.deactivate
		local oldInstance = versionData.instance
		
		versionData.deactivate = deactivate
		
		local skipCopy
		if type(activate) == "function" then
			 skipCopy = activate(newInstance, oldInstance)
		end

		-- Deactivate the old libary if necessary
		if type(oldDeactivate) == "function" then
			oldDeactivate(oldInstance, newInstance)
		end

		-- Re-use the old table, and discard the new one
		if not skipCopy then
			NilCopyTable(newInstance, oldInstance)
		end
		return oldInstance
	end

	function lib:GetVersion() return major,minor end

	local function Activate(new, old)
		if old then
			new.versions = old.versions
		end
		g.DongleStub = new
	end
	
	-- Actually trigger libary activation here
	local stub = g.DongleStub or lib
	stub:Register(lib, Activate)
end

--[[-------------------------------------------------------------------------
  Begin Library Implementation
---------------------------------------------------------------------------]]

local majorUtil, majorGrat, majorMetro = "DongleUtils-Beta0", "GratuityMini-Beta0", "MetrognomeNano-Beta0"
local minor = tonumber(string.match("$Revision: 250 $", "(%d+)") or 1)

assert(DongleStub, string.format("DongleUtils requires DongleStub.", major))
assert(DongleStub and DongleStub:GetVersion() == "DongleStub-Beta0",
	string.format("DongleUtils requires DongleStub-Beta0.  You are using an older version.", major))

if not DongleStub:IsNewerVersion(majorUtil, minor) then return end

--------------------------------
--        DongleUtils         --
--      Misc handy utils      --
--------------------------------

local DongleUtils = {}


function DongleUtils:GetVersion()
	return majorUtil, minor
end


---------------------------
-- Common locale strings --
---------------------------

local locale = GetLocale()
-- Localized class names.  Index == enUS, value == localized
DongleUtils.classnames = locale == "deDE" and {
	["Warlock"] = "Hexenmeister",
	["Warrior"] = "Krieger",
	["Hunter"] = "Jäger",
	["Mage"] = "Magier",
	["Priest"] = "Priester",
	["Druid"] = "Druide",
	["Paladin"] = "Paladin",
	["Shaman"] = "Schamane",
	["Rogue"] = "Schurke",
} or locale == "frFR" and {
	["Warlock"] = "D\195\169moniste",
	["Warrior"] = "Guerrier",
	["Hunter"] = "Chasseur",
	["Mage"] = "Mage",
	["Priest"] = "Pr\195\170tre",
	["Druid"] = "Druide",
	["Paladin"] = "Paladin",
	["Shaman"] = "Chaman",
	["Rogue"] = "Voleur",
} or {
	["Warlock"] = "Warlock",
	["Warrior"] = "Warrior",
	["Hunter"] = "Hunter",
	["Mage"] = "Mage",
	["Priest"] = "Priest",
	["Druid"] = "Druid",
	["Paladin"] = "Paladin",
	["Shaman"] = "Shaman",
	["Rogue"] = "Rogue",
}

-- Reversed version of .classnames, for locale -> enUS translation
DongleUtils.classnamesreverse = {}
for i,v in pairs(DongleUtils.classnames) do DongleUtils.classnamesreverse[v] = i end


-- Handy method to attach to secure frames, to aid in setting attributes quickly
-- Example: someframe:SetManyAttributes("type1", "spell", "spell", "Innervate", "unit1", "player")
function DongleUtils.SetManyAttributes(self, ...)
	for i=1,select("#", ...),2 do
		local att,val = select(i, ...)
		if not att then return end
		self:SetAttribute(att,val)
	end
end


function DongleUtils.RGBToHex(r, g, b)
	return string.format("%02x%02x%02x", r, g, b)
end


function DongleUtils.RGBPercToHex(r, g, b)
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end


function DongleUtils.HexToRGB(hex)
	local rhex, ghex, bhex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)
	return tonumber(rhex, 16), tonumber(ghex, 16), tonumber(bhex, 16)
end


function DongleUtils.HexToRGBPerc(hex)
	local rhex, ghex, bhex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)
	return tonumber(rhex, 16)/255, tonumber(ghex, 16)/255, tonumber(bhex, 16)/255
end


function DongleUtils.ColorGradient(perc, ...)
	local num = select("#", ...)
	local hexes = type(select(1, ...)) == "string"

	if perc == 1 then
		if hexes then return select(num, ...)
		else return select(num-2, ...), select(num-1, ...), select(num, ...) end
	end

	if not hexes then num = num / 3 end

	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2
	if hexes then
		r1, g1, b1 = DongleUtils.HexToRGBPerc(select(segment+1, ...))
		r2, g2, b2 = DongleUtils.HexToRGBPerc(select(segment+2, ...))
	else
		r1, g1, b1 = select((segment*3)+1, ...), select((segment*3)+2, ...), select((segment*3)+3, ...)
		r2, g2, b2 = select((segment*3)+4, ...), select((segment*3)+5, ...), select((segment*3)+6, ...)
	end

	if hexes then
		return DongleUtils.RGBToHex(r1 + (r2-r1)*relperc,
			g1 + (g2-g1)*relperc,
			b1 + (b2-b1)*relperc)
	else
		return r1 + (r2-r1)*relperc,
			g1 + (g2-g1)*relperc,
			b1 + (b2-b1)*relperc
	end
end


function DongleUtils.GetHPSeverity(perc, class)
	if not class then return DongleUtils.ColorGradient(perc, 1,0,0, 1,1,0, 0,1,0)
	else
		local c = RAID_CLASS_COLORS[class]
		return DongleUtils.ColorGradient(perc, 1,0,0, 1,1,0, c.r,c.g,c.b)
	end
end


DongleUtils = DongleStub:Register(DongleUtils)


---------------------------------------
--           GratuityMini            --
--      Tooltip parsing library      --
---------------------------------------

local GratuityMini = {}

function GratuityMini:GetVersion()
	return majorGrat, minor
end


local function GratuityMini_Activate(new, old)
	if old then
		new.tooltip = old.tooltip
		return
	end

	local tip = CreateFrame("GameTooltip")
	tip:SetOwner(WorldFrame, "ANCHOR_NONE")
	tip.Llines, tip.Rlines = {}, {}
	for i=1,30 do
		tip.Llines[i], tip.Rlines[i] = tip:CreateFontString(), tip:CreateFontString()
		tip.Llines[i]:SetFontObject(GameFontNormal); tip.Rlines[i]:SetFontObject(GameFontNormal)
		tip:AddFontStrings(tip.Llines[i], tip.Rlines[i])
	end

	tip.Erase = function(self)
		self:ClearLines() -- Ensures tooltip's NumLines is reset
		for i=1,30 do
			self.Rlines[i]:SetText() -- Clear text from right side (ClearLines only hides them)
			self.L[i], self.R[i] = nil, nil -- Flush the metatable cache
		end
		if not self:IsOwned(WorldFrame) then self:SetOwner(WorldFrame, "ANCHOR_NONE") end
	end

	local methods = {"SetMerchantCostItem", "SetBagItem", "SetAction", "SetAuctionItem", "SetAuctionSellItem", "SetBuybackItem",
		"SetCraftItem", "SetCraftSpell", "SetHyperlink", "SetInboxItem", "SetInventoryItem", "SetLootItem", "SetLootRollItem",
		"SetMerchantItem", "SetPetAction", "SetPlayerBuff", "SetQuestItem", "SetQuestLogItem", "SetQuestRewardSpell",
		"SetSendMailItem", "SetShapeshift", "SetSpell", "SetTalent", "SetTrackingSpell", "SetTradePlayerItem", "SetTradeSkillItem",
		"SetTradeTargetItem", "SetTrainerService", "SetUnit", "SetUnitBuff", "SetUnitDebuff"}
	for _,m in pairs(methods) do
		local orig = tip[m]
		tip[m] = function(self, ...)
			self:Erase()
			return orig(self, ...)
		end
	end

	tip.L, tip.R = {}, {}
	setmetatable(tip.L, {
		__index = function(t, key)
			if tip:NumLines() >= key and tip.Llines[key] then
				local v = tip.Llines[key]:GetText()
				t[key] = v
				return v
			end
			return nil
		end,
	})
	setmetatable(tip.R, {
		__index = function(t, key)
			if tip:NumLines() >= key and tip.Rlines[key] then
				local v = tip.Rlines[key]:GetText()
				t[key] = v
				return v
			end
			return nil
		end,
	})

	new.tooltip = tip
end


function GratuityMini:GetTooltip()
	return self.tooltip
end


GratuityMini = DongleStub:Register(GratuityMini, GratuityMini_Activate)


--------------------------------------------------
--                MetrognomeNano                --
--      OnUpdate and delayed event manager      --
--------------------------------------------------

local Metrognome = {}
local frame, handlers, eventargs


function Metrognome:GetVersion()
	return majorMetro, minor
end


local function Metrognome_Activate(new, old)
	new.eventargs = old and old.eventargs or {}
	new.handlers = old and old.handlers or {}
	new.frame = old and old.frame or CreateFrame("Frame")
	handlers, frame, eventargs = new.handlers, new.frame, new.eventargs
	if not old then frame:Hide() end
	frame.name = "MetrognomeNano Frame"
	frame:SetScript("OnUpdate", new.OnUpdate)
end


function Metrognome:SendDelayedMessage(delay, message, ...)
	local id = message..GetTime()

	self:Register(self, id, "DelayedMessageHandler", rate, id, message, ...)
	self:Start(id, 1)

	return id
end


function Metrognome:DelayedMessageHandler(id, ...)
	self:Unregister(id)

	if Dongle then Dongle:TriggerMessage(...) end
end


function Metrognome:Register(addon, name, func, rate, ...)
--~ 	self:argCheck(name, 2, "string")
--~ 	self:argCheck(func, 3, "function")
--~ 	self:assert(not handlers[name], "A timer with the name "..name.." is already registered")

	handlers[name] = {
		handler = type(func) == "string" and addon,
		name = name,
		func = func,
		rate = rate or 0,
		...
	}

	return true
end


function Metrognome:Unregister(name)
--~ 	self:argCheck(name, 2, "string")

	if not handlers[name] then return end
	handlers[name] = nil
	if not next(handlers) then frame:Hide() end
	return true
end


function Metrognome:Start(name, numexec)
--~ 	self:argCheck(name, 2, "string")

	if not handlers[name] then return end
	handlers[name].limit = numexec
	handlers[name].elapsed = 0
	handlers[name].running = true
	frame:Show()
	return true
end


function Metrognome:Stop(name)
--~ 	self:argCheck(name, 2, "string")

	if not handlers[name] then return end
	handlers[name].running = nil
	handlers[name].limit = nil
	if not next(handlers) then frame:Hide() end
	return true
end


function Metrognome:ChangeRate(name, newrate)
--~ 	self:argCheck(name, 2, "string")

	if not handlers[name] then return end

	local t = handlers[name]
	t.elapsed = 0
	t.rate = newrate or 0
	return true
end


function Metrognome:GetHandlerTable(name)
--~ 	self:argCheck(name, 2, "string")

	return handlers[name]
end


function Metrognome.OnUpdate(frame, elapsed)
	for i,v in pairs(handlers) do
		if v.running then
			v.elapsed = v.elapsed + elapsed
			if v.elapsed >= v.rate then
				if v.handler then v.handler[v.func](v.handler, v.elapsed, unpack(v))
				else v.func(v.elapsed, unpack(v)) end
				v.elapsed = 0
				if v.limit then
					v.limit = v.limit - 1
					if v.limit <= 0 then Metrognome:Stop(i) end
				end
			end
		end
	end
end


Metrognome = DongleStub:Register(Metrognome, Metrognome_Activate)

