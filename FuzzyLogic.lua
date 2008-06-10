
-- Only load for hunters
if select(2, UnitClass("player")) ~= "HUNTER" then
	DisableAddOn("FuzzyLogic")
	return
end


----------------------------
--      Localization      --
----------------------------

local L = GetLocale() == "deDE" and {
	petdead = "Euer Begleiter ist tot.",
	petmend = "Tier heilen",
	petcall = "Tier rufen",
	petdis = "Tier freigeben",
	petrevive = "Tier wiederbeleben",
	macro = "/cast [target=pet,dead] Tier wiederbeleben; [nopet] Tier rufen; Tier heilen",
	macrodead = "/cast [target=pet,dead] Tier wiederbeleben; [nopet] Tier wiederbeleben; Tier heilen",
} or {
	petdead = "Your pet is dead.",
	petmend = "Mend Pet",
	petcall = "Call Pet",
	petdis = "Dismiss Pet",
	petrevive = "Revive Pet",
	macro = "/cast [target=pet,dead] Revive Pet; [nopet] Call Pet; Mend Pet",
	macrodead = "/cast [target=pet,dead] Revive Pet; [nopet] Revive Pet; Mend Pet",
}


------------------------------
--      Are you local?      --
------------------------------

local healthresh = 0.90 -- Change this to the threshold you want to cast Mend Pet instead of Dismiss
local binding -- Set this to the key you wish to be bound
local petIsDead, frame, hasImpMendPet


local function SetManyAttributes(self, ...)
	for i=1,select("#", ...),2 do
		local att,val = select(i, ...)
		if not att then return end
		self:SetAttribute(att,val)
	end
end


-------------------------------------
--      Namespace Declaration      --
-------------------------------------

FuzzyLogic = DongleStub("Dongle-1.0"):New("FuzzyLogic")


------------------------------
--      Initialization      --
------------------------------

function FuzzyLogic:Initialize()
	frame = CreateFrame("Button", "FuzzyLogicFrame", UIParent, "SecureActionButtonTemplate")
	if binding then SetBindingClick(binding, "FuzzyLogicFrame") end
	frame.SetManyAttributes = SetManyAttributes
	frame:Hide()

	frame:SetScript("PreClick", self.PreClick)
end


function FuzzyLogic:Enable()
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("UNIT_HEALTH")

	hasImpMendPet = select(5, GetTalentInfo(1, 10)) > 0
end


------------------------------
--      Event Handlers      --
------------------------------

function FuzzyLogic:UI_ERROR_MESSAGE(event, msg)
	if msg == L.petdead then petIsDead = true end
end


function FuzzyLogic:PLAYER_REGEN_DISABLED()
	self:Debug(1, "Entering Combat")
	frame:SetManyAttributes("type1", "macro", "macrotext", petIsDead and L.macrodead or L.macro)
end


function FuzzyLogic:UNIT_HEALTH(event, unit)
	if unit ~= "pet" then return end

	local hp = UnitHealth("pet")
	if petIsDead and hp > 0 then
		self:Debug(1, "Pet alive again")
		petIsDead = false
	elseif not petIsDead and hp == 0 then
		self:Debug(1, "Pet died")
		petIsDead = true
	end
end


------------------------------
--      Frame Handlers      --
------------------------------

function FuzzyLogic.PreClick()
	if InCombatLockdown() then return end

	local exists = UnitExists("pet")
	if UnitIsDead("pet") or (not exists and petIsDead) then
		frame:SetManyAttributes("type1", "spell", "spell", L.petrevive)
	elseif exists then
		if (UnitHealth("pet")/UnitHealthMax("pet") < healthresh) or (hasImpMendPet and UnitDebuff("pet", 1)) then
			frame:SetManyAttributes("type1", "spell", "spell", L.petmend)
		else
			frame:SetManyAttributes("type1", "spell", "spell", L.petdis)
		end
	else
		frame:SetManyAttributes("type1", "spell", "spell", L.petcall)
	end
end
