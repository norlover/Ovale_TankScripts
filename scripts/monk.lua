local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
	local name = "icyveins_monk_brewmaster"
	local desc = "[8.0.1] Icy-Veins: Monk Brewmaster"
	local code = [[
Include(ovale_common)
Include(ovale_monk_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=brewmaster)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=brewmaster)
AddCheckBox(opt_monk_bm_aoe L(AOE) default specialization=brewmaster)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=brewmaster)

AddFunction BrewmasterHealMeShortCd
{
	unless(DebuffPresent(healing_immunity_debuff)) 
	{
		if (HealthPercent() < 35) 
		{
			Spell(healing_elixir)
			Spell(expel_harm)
		}
		if (HealthPercent() <= 100 - (15 * 2.6)) Spell(healing_elixir)
		if (HealthPercent() < 35) UseHealthPotions()
	}
}

AddFunction BrewmasterHealMeMain
{
	unless(DebuffPresent(healing_immunity_debuff)) 
	{
	}
}

AddFunction StaggerPercentage
{
	StaggerRemaining() / MaxHealth() * 100
}

AddFunction BrewmasterRangeCheck
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction BrewmasterDefaultShortCDActions
{
	# keep ISB up always when taking dmg
	if ((BaseDuration(light_stagger_debuff)-DebuffRemaining(any_stagger_debuff)<5 or target.IsTargetingPlayer()) and BuffExpires(ironskin_brew_buff 3) and BuffExpires(blackout_combo_buff)) Spell(ironskin_brew text=min)
	
	# keep stagger below 100% (70% when in a party, 30% when BOB is up)
	if (StaggerPercentage() >= 100 or (StaggerPercentage() >= 70 and not UnitInRaid()) or (StaggerPercentage() >= 30 and Talent(black_ox_brew_talent) and SpellCooldown(black_ox_brew) <= 0)) Spell(purifying_brew)
	# use black_ox_brew when at 0 charges and low energy (or in an emergency)
	if (SpellCharges(ironskin_brew count=0) <= 0.75)
	{
		#black_ox_brew,if=incoming_damage_1500ms&stagger.heavy&cooldown.brews.charges_fractional<=0.75
		if IncomingDamage(1.5) > 0 and DebuffPresent(heavy_stagger_debuff) Spell(black_ox_brew)
		#black_ox_brew,if=(energy+(energy.regen*cooldown.keg_smash.remains))<40&buff.blackout_combo.down&cooldown.keg_smash.up
		if Energy() + EnergyRegenRate() * SpellCooldown(keg_smash) < 40 and BuffExpires(blackout_combo_buff) and not SpellCooldown(keg_smash) > 0 Spell(black_ox_brew)
	}
	
	# heal me
	BrewmasterHealMeShortCd()
	# Guard
	Spell(guard)
	# range check
	BrewmasterRangeCheck()

	unless StaggerPercentage() > 100
	{
		# purify heavy stagger when we have enough ISB
		if (StaggerPercentage() >= 60 and (BuffRemaining(ironskin_brew_buff) >= 2*BaseDuration(ironskin_brew_buff))) Spell(purifying_brew)

		# always bank 1 charge
		unless (SpellCharges(ironskin_brew) <= 1)
		{
			# keep ISB rolling
			if BuffRemaining(ironskin_brew_buff) < DebuffRemaining(any_stagger_debuff) and BuffExpires(blackout_combo_buff) Spell(ironskin_brew)
			
			# never be at (almost) max charges 
			unless (SpellFullRecharge(ironskin_brew) > 3)
			{
				if (BuffRemaining(ironskin_brew_buff) < 2*BaseDuration(ironskin_brew_buff) and BuffExpires(blackout_combo_buff)) Spell(ironskin_brew text=max)
				if (StaggerPercentage() > 30 or Talent(special_delivery_talent)) Spell(purifying_brew text=max)
			}
		}
	}
}

#
# Single-Target
#

AddFunction BrewmasterDefaultMainActions
{
	BrewmasterHealMeMain()
		
	if Talent(blackout_combo_talent) BrewmasterBlackoutComboMainActions()
	unless Talent(blackout_combo_talent) 
	{
		Spell(keg_smash)
		unless (SpellCooldown(keg_smash) < GCD()) 
		{
			Spell(blackout_strike)
			if (target.DebuffPresent(keg_smash)) Spell(breath_of_fire)
			if (BuffRefreshable(rushing_jade_wind_buff)) Spell(rushing_jade_wind)
			if (Energy() >= 65 or (Talent(black_ox_brew_talent) and SpellCooldown(black_ox_brew) <= 0)) Spell(tiger_palm)
			Spell(chi_burst)
			Spell(chi_wave)
			Spell(arcane_pulse)
		}
	}
}

AddFunction BrewmasterBlackoutComboMainActions
{
	if(BuffPresent(blackout_combo_buff)) Spell(tiger_palm)
	unless (BuffPresent(blackout_combo_buff)) 
	{
		Spell(keg_smash)
		unless (SpellCooldown(keg_smash) < GCD())
		{
			Spell(blackout_strike)
			if target.DebuffPresent(keg_smash) Spell(breath_of_fire)
			if BuffRefreshable(rushing_jade_wind_buff) 
			Spell(chi_burst)
			Spell(chi_wave)
			Spell(arcane_pulse)
			Spell(rushing_jade_wind)
		}
	}
}

#
# AOE
#

AddFunction BrewmasterDefaultAoEActions
{
	BrewmasterHealMeMain()
	Spell(keg_smash)
	unless (SpellCooldown(keg_smash) < GCD()) 
	{
		if (Talent(blackout_combo_talent) and not BuffPresent(blackout_combo_buff)) Spell(blackout_strike)
		Spell(chi_burst)
		Spell(chi_wave)
		if (target.DebuffPresent(keg_smash) and not BuffPresent(blackout_combo_buff)) Spell(breath_of_fire)
		if (BuffRefreshable(rushing_jade_wind_buff)) Spell(rushing_jade_wind)
		Spell(arcane_pulse)
		if (Energy() >= 65 or (Talent(black_ox_brew_talent) and SpellCooldown(black_ox_brew) <= 0)) Spell(tiger_palm)
		if (not BuffPresent(blackout_combo_buff)) Spell(blackout_strike)
		Spell(rushing_jade_wind)
	}
}

AddFunction BrewmasterDefaultCdActions 
{
	if not CheckBoxOn(opt_monk_bm_offensive) 
	{
		BrewmasterInterruptActions()
		BrewmasterDefaultOffensiveCooldowns()
	}
	Item(Trinket0Slot usable=1 text=13)
	Item(Trinket1Slot usable=1 text=14)
	Spell(fortifying_brew)
	Spell(dampen_harm)
	if CheckBoxOn(opt_use_consumables) 
	{
		Item(battle_potion_of_agility usable=1)
		Item(steelskin_potion usable=1)
		Item(battle_potion_of_stamina usable=1)
	}
	Spell(zen_meditation)
	UseRacialSurvivalActions()
}

AddFunction BrewmasterInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(spear_hand_strike) and target.IsInterruptible() Spell(spear_hand_strike)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(leg_sweep)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.InRange(paralysis) and not target.Classification(worldboss) Spell(paralysis)
	}
}

AddFunction BrewmasterDefaultOffensiveCooldowns
{
	if not PetPresent(name=Niuzao) Spell(invoke_niuzao_the_black_ox)
}

AddIcon help=shortcd specialization=brewmaster
{
	BrewmasterDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=brewmaster
{
	BrewmasterDefaultMainActions()
}

AddIcon checkbox=opt_monk_bm_aoe help=aoe specialization=brewmaster
{
	BrewmasterDefaultAoEActions()
}

AddIcon help=cd specialization=brewmaster
{
	BrewmasterDefaultCdActions()
}

AddCheckBox(opt_monk_bm_offensive L(opt_monk_bm_offensive) default specialization=brewmaster)
AddIcon checkbox=opt_monk_bm_offensive size=small specialization=brewmaster
{
	BrewmasterInterruptActions()
	BrewmasterDefaultOffensiveCooldowns()
}
]]
	OvaleScripts:RegisterScript("MONK", "brewmaster", name, desc, code, "script")
end