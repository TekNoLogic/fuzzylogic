BINDING_HEADER_FUZZYLOGIC = "Fuzzy Logic"

FuzzyLogic = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0")

local petIsDead

local L = GetLocale() == "deDE" and {
	petdead = "Euer Begleiter ist tot.",
	petmend = "Tier heilen",
	petcall = "Tier rufen",
	petdis = "Tier freigeben",
	petrevive = "Tier wiederbeleben",
} or {
	petdead = "Your pet is dead.",
	petmend = "Mend Pet",
	petcall = "Call Pet",
	petdis = "Dismiss Pet",
	petrevive = "Revive Pet",
}


function FuzzyLogic:OnEnable()
	self:RegisterEvent("UI_ERROR_MESSAGE")
end


function FuzzyLogic:UI_ERROR_MESSAGE(msg)
	if msg == L.petdead then petIsDead = true end
end


function FuzzyLogic:Trigger()
	if UnitAffectingCombat("player") then return end
	if petIsDead or UnitIsDead("pet") then
		petIsDead = nil
		CastSpellByName(L.petrevive)
	elseif UnitExists("pet") and (UnitHealth("pet")/UnitHealthMax("pet") < .90) then
		CastSpellByName(L.petmend)
	elseif UnitExists("pet") then CastSpellByName(L.petdis)
	else CastSpellByName(L.petcall) end
end