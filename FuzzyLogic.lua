
-- Only load for hunters
if select(2, UnitClass("player")) ~= "HUNTER" then
	DisableAddOn("FuzzyLogic")
	return
end

local L = GetLocale() == "deDE" and {
	petmend = "Tier heilen",
	petcall = "Tier rufen",
	petdis = "Tier freigeben",
	petrevive = "Tier wiederbeleben",
} or {
	petmend = "Mend Pet",
	petcall = "Call Pet",
	petdis = "Dismiss Pet",
	petrevive = "Revive Pet",
}

local healthresh = 0.90 -- Change this to the threshold you want to cast Mend Pet instead of Dismiss
local binding -- Set this to the key you wish to be bound
local macro = "/cast [target=pet,dead] ".. L.petrevive.. "; [nopet] ".. L.petcall.. "; ".. L.petmend

local frame = CreateFrame("Button", "FuzzyLogicFrame", UIParent, "SecureActionButtonTemplate")
if binding then SetBindingClick(binding, "FuzzyLogicFrame") end
frame.SetManyAttributes = DongleStub("DongleUtils").SetManyAttributes
frame:Hide()

frame:SetScript("PreClick", function()
	if InCombatLockdown() then return end

	-- PetCanBeAbandoned() will return true if your pet is dismissed and false if your pet is dead
	if UnitExists("pet") and UnitIsDead("pet") or (not UnitExists("pet") and not PetCanBeAbandoned()) then
		frame:SetManyAttributes("type1", "spell", "spell", L.petrevive)
	elseif UnitExists("pet") and (UnitHealth("pet")/UnitHealthMax("pet") < healthresh) then
		frame:SetManyAttributes("type1", "spell", "spell", L.petmend)
	elseif UnitExists("pet") then frame:SetManyAttributes("type1", "spell", "spell", L.petdis)
	else frame:SetManyAttributes("type1", "spell", "spell", L.petcall) end
end)

frame:SetScript("PostClick", function()
	if InCombatLockdown() then return end

	-- PetCanBeAbandoned() will return true if your pet is dismissed and false if your pet is dead
	if UnitExists("pet") and UnitIsDead("pet") or (not UnitExists("pet") and not PetCanBeAbandoned()) then
		frame:SetManyAttributes("type1", "spell", "spell", L.petrevive)
	else frame:SetManyAttributes("type1", "macro", "macrotext", macro) end
end)

