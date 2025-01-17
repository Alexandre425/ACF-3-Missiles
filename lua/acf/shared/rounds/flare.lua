
ACF.AmmoBlacklist.FLR = { "AC", "AL", "C", "HMG", "HW", "MG", "MO", "RAC", "SA", "SC", "SAM", "AAM", "ASM", "BOMB", "FFAR", "UAR", "GBU", "ARTY" }

local Round = {}

Round.type = "Ammo" --Tells the spawn menu what entity to spawn
Round.name = "Flare (FLR)" --Human readable name
Round.model = "models/munitions/round_100mm_shot.mdl" --Shell flight model
Round.desc = "A flare designed to confuse guided munitions."

function Round.create(_, BulletData)
	local Bullet = ACF_CreateBullet(BulletData)

	Bullet.CreateTime = CurTime()

	ACFM_RegisterFlare(Bullet)
end

-- Function to convert the player's slider data into the complete round data
function Round.convert(_, PlayerData)
	local Data = {}
	local ServerData = {}
	local GUIData = {}

	if not PlayerData.PropLength then PlayerData.PropLength = 0 end
	if not PlayerData.ProjLength then PlayerData.ProjLength = 0 end
	if not PlayerData.Data5 then PlayerData.Data5 = 0 end
	if not PlayerData.Data10 then PlayerData.Data10 = 0 end

	PlayerData, Data, ServerData, GUIData = ACF_RoundBaseGunpowder( PlayerData, Data, ServerData, GUIData )

	--Shell sturdiness calcs
	Data.ProjMass = math.max(GUIData.ProjVolume - PlayerData.Data5, 0) * 7.9 / 1000 + math.min(PlayerData.Data5, GUIData.ProjVolume) * ACF.HEDensity / 1000 --Volume of the projectile as a cylinder - Volume of the filler * density of steel + Volume of the filler * density of TNT
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)

	local Energy = ACF_Kinetic(Data.MuzzleVel * 39.37 , Data.ProjMass, Data.LimitVel)
	local MaxVol = ACF_RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)

	GUIData.MinFillerVol = 0
	GUIData.MaxFillerVol = math.min(GUIData.ProjVolume, MaxVol * 0.9)
	GUIData.FillerVol = math.min(PlayerData.Data5, GUIData.MaxFillerVol)
	Data.FillerMass = GUIData.FillerVol * ACF.HEDensity / 1000

	Data.ProjMass = math.max(GUIData.ProjVolume-GUIData.FillerVol,0) * 7.9 / 1000 + Data.FillerMass
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)

	--Random bullshit left
	Data.ShovePower = 0.1
	Data.PenArea = Data.FrArea^ACF.PenAreaMod
	Data.DragCoef = (Data.FrArea / 375) / Data.ProjMass
	Data.LimitVel = 700										--Most efficient penetration speed in m/s
	Data.KETransfert = 0.1									--Kinetic energy transfert to the target for movement purposes
	Data.Ricochet = 75										--Base ricochet angle

	Data.BurnRate = Data.FrArea * ACFM.FlareBurnMultiplier
	Data.DistractChance = (2 / math.pi) * math.atan(Data.FrArea * ACFM.FlareDistractMultiplier)	* 0.5	--reduced effectiveness 50%--red
	Data.BurnTime = Data.FillerMass / Data.BurnRate

	Data.CartMass = Data.ProjMass + Data.PropMass

	if SERVER then --Only the crates need this part
		ServerData.Id = PlayerData.Id
		ServerData.Type = PlayerData.Type

		return table.Merge(Data,ServerData)
	end

	if CLIENT then --Only tthe GUI needs this part
		GUIData = table.Merge(GUIData, Round.getDisplayData(Data))

		return table.Merge(Data,GUIData)
	end
end

function Round.getDisplayData(Data)
	local GUIData = {}

	GUIData.MaxPen = 0

	GUIData.BurnRate = Data.BurnRate
	GUIData.DistractChance = Data.DistractChance
	GUIData.BurnTime = Data.BurnTime

	return GUIData
end

function Round.network(Crate, BulletData)
	Crate:SetNWString("AmmoType", "FLR")
	Crate:SetNWString("AmmoID", BulletData.Id)
	Crate:SetNWFloat("Caliber", BulletData.Caliber)
	Crate:SetNWFloat("ProjMass", BulletData.ProjMass)
	Crate:SetNWFloat("FillerMass", BulletData.FillerMass)
	Crate:SetNWFloat("PropMass", BulletData.PropMass)
	Crate:SetNWFloat("DragCoef", BulletData.DragCoef)
	Crate:SetNWFloat("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNWFloat("Tracer", BulletData.Tracer)
end

function Round.cratetxt(BulletData)
	local DData = Round.getDisplayData(BulletData)

	local Text = {
		"Muzzle Velocity: ", math.Round(BulletData.MuzzleVel, 1), " m/s\n",
		"Burn Rate: ", math.Round(DData.BurnRate, 1), " kg/s\n",
		"Burn Duration: ", math.Round(DData.BurnTime, 1), " s\n",
		"Distract Chance: ", math.floor(DData.DistractChance * 100), " %"
	}

	return table.concat(Text)
end

local IgniteConvar = GetConVar("ACFM_FlaresIgnite")

function Round.propimpact(_, _, Target)
	if IgniteConvar:GetBool() then
		local Type = ACF_Check(Target)

		if Type == "Squishy" and ((Target:IsPlayer() and not Target:HasGodMode()) or Target:IsNPC()) then
			Target:Ignite(30)
		end
	end

	return false
end

function Round.worldimpact()
	return false
end

function Round.endflight( Index)
	ACF_RemoveBullet( Index )
end

local DecalIndex = ACF.GetAmmoDecalIndex

function Round.endeffect()
end

function Round.pierceeffect(_, Bullet)
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetScale(Bullet.SimFlight:Length())
	Effect:SetMagnitude(Bullet.RoundMass)
	Effect:SetRadius(Bullet.Caliber)
	Effect:SetDamageType(DecalIndex(Bullet.AmmoType))

	util.Effect("ACF_Penetration", Effect)
end

function Round.ricocheteffect(_, Bullet)
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetScale(Bullet.SimFlight:Length())
	Effect:SetMagnitude(Bullet.RoundMass)
	Effect:SetRadius(Bullet.Caliber)
	Effect:SetDamageType(DecalIndex(Bullet.AmmoType))

	util.Effect("ACF_Ricochet", Effect)
end

function Round.guicreate( Panel, Table )
	acfmenupanel:AmmoSelect(ACF.AmmoBlacklist.FLR)

	acfmenupanel:CPanelText("BonusDisplay", "")

	acfmenupanel:CPanelText("Desc", "")	--Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "")	--Total round length (Name, Desc)

	acfmenupanel:AmmoSlider("PropLength", 0, 0, 1000, 3, "Propellant Length", "")	--Propellant Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", 0, 0, 1000, 3, "Projectile Length", "")	--Projectile Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol", 0, 0, 1000, 3, "Dual Spectrum Filler", "") --Hollow Point Cavity Slider (Name, Value, Min, Max, Decimals, Title, Desc)

	acfmenupanel:CPanelText("VelocityDisplay", "")	--Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("BurnRateDisplay", "")	--Proj muzzle penetration (Name, Desc)
	acfmenupanel:CPanelText("BurnDurationDisplay", "")	--HE Blast data (Name, Desc)
	acfmenupanel:CPanelText("DistractChanceDisplay", "")	--HE Fragmentation data (Name, Desc)

	Round.guiupdate( Panel, Table )
end

function Round.guiupdate(Panel)
	local PlayerData = {
		Id = acfmenupanel.AmmoData.Data.id,					--AmmoSelect GUI
		Type = "FLR",										--Hardcoded, match ACFRoundTypes table index
		PropLength = acfmenupanel.AmmoData.PropLength,		--PropLength slider
		ProjLength = acfmenupanel.AmmoData.ProjLength,		--ProjLength slider
		Data5 = acfmenupanel.AmmoData.FillerVol,
		Data10 = acfmenupanel.AmmoData.Tracer and 1 or 0,	--Tracer
	}

	local Data = Round.convert( Panel, PlayerData )

	RunConsoleCommand("acfmenu_data1", acfmenupanel.AmmoData.Data.id)
	RunConsoleCommand("acfmenu_data2", PlayerData.Type)
	RunConsoleCommand("acfmenu_data3", Data.PropLength)		--For Gun ammo, Data3 should always be Propellant
	RunConsoleCommand("acfmenu_data4", Data.ProjLength)		--And Data4 total round mass
	RunConsoleCommand("acfmenu_data5", Data.FillerVol)
	RunConsoleCommand("acfmenu_data10", Data.Tracer)

	acfmenupanel:AmmoSlider("PropLength", Data.PropLength, Data.MinPropLength, Data.MaxTotalLength, 3, "Propellant Length", "Propellant Mass : " .. math.floor(Data.PropMass * 1000) .. " g")	--Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", Data.ProjLength, Data.MinProjLength, Data.MaxTotalLength, 3, "Projectile Length", "Projectile Mass : " .. math.floor(Data.ProjMass * 1000) .. " g")	--Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol", Data.FillerVol, Data.MinFillerVol, Data.MaxFillerVol, 3, "Dual Spectrum Filler", "Filler Mass : " .. math.floor(Data.FillerMass * 1000) .. " g")	--HE Filler Slider (Name, Min, Max, Decimals, Title, Desc)

	acfmenupanel:CPanelText("Desc", ACF.RoundTypes[PlayerData.Type].desc)	--Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "Round Length : " .. math.floor((Data.PropLength + Data.ProjLength + Data.Tracer) * 100) / 100 .. "/" .. Data.MaxTotalLength .. " cm")	--Total round length (Name, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "Muzzle Velocity : " .. math.floor(Data.MuzzleVel * ACF.Scale) .. " m/s")	--Proj muzzle velocity (Name, Desc)

	acfmenupanel:CPanelText("BurnRateDisplay", "Burn Rate : " .. math.Round(Data.BurnRate, 1) .. " kg/s")
	acfmenupanel:CPanelText("BurnDurationDisplay", "Burn Duration : " .. math.Round(Data.BurnTime, 1) .. " s")
	acfmenupanel:CPanelText("DistractChanceDisplay", "Distraction Chance : " .. math.floor(Data.DistractChance * 100) .. " %")
end

ACF.RoundTypes.FLR = Round --Set the round properties

ACF.RegisterAmmoDecal("FLR", "damage/ap_pen", "damage/ap_rico")