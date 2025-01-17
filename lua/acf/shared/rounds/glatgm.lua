
ACF.AmmoBlacklist.GLATGM = { "AC", "HMG", "MG", "RAC", "SA", "SAM", "AAM", "ASM", "BOMB", "FFAR", "UAR", "GBU", "GL", "SL", "FGL", "ARTY" }

local Round = {}

Round.type = "Ammo" --Tells the spawn menu what entity to spawn
Round.name = "Gun-Launched Anti-Tank Missile (GLATGM)" --Human readable name
Round.model = "models/munitions/round_100mm_shot.mdl" --Shell flight model
Round.desc = "A missile fired from a gun. While slower than a traditional shell it makes up for that with guidance."

function Round.create(Gun, BulletData)
	if Gun:GetClass() == "acf_ammo" then
		ACF_CreateBullet( BulletData )
	else
		local GLATGM = ents.Create("acf_glatgm")
		GLATGM.Owner = Gun.Owner
		GLATGM.DoNotDuplicate = true
		GLATGM.Guidance = Gun
		GLATGM:SetAngles(Gun:GetAngles())
		GLATGM:SetPos(Gun:GetAttachment(1).Pos) -- + Gun:GetForward()*24)
		GLATGM.BulletData = BulletData
		GLATGM.Distance = BulletData.MuzzleVel * 4 * 39.37 -- optical fuse distance
		GLATGM:Spawn()
	end
end

function Round.ConeCalc(ConeAngle, Radius)
	local ConeLength = math.tan(math.rad(ConeAngle)) * Radius
	local ConeArea = 3.1416 * Radius * (Radius * Radius + ConeLength * ConeLength) ^ 0.5
	local ConeVol = (3.1416 * Radius * Radius * ConeLength) / 3

	return ConeLength, ConeArea, ConeVol
end

-- Function to convert the player's slider data into the complete round data
function Round.convert(Crate, PlayerData)
	local Data = {}
	local ServerData = {}
	local GUIData = {}

	if not PlayerData.PropLength then PlayerData.PropLength = 0 end
	if not PlayerData.ProjLength then PlayerData.ProjLength = 0 end
	PlayerData.Data5 = math.max(PlayerData.Data5 or 0, 0)
	if not PlayerData.Data6 then PlayerData.Data6 = 0 end
	if not PlayerData.Data7 then PlayerData.Data7 = 0 end
	if not PlayerData.Data10 then PlayerData.Data10 = 0 end

	PlayerData, Data, ServerData, GUIData = ACF_RoundBaseGunpowder(PlayerData, Data, ServerData, GUIData)

	local ConeThick = Data.Caliber / 50
	local ConeArea = 0
	local AirVol = 0
	ConeLength, ConeArea, AirVol = Round.ConeCalc(PlayerData.Data6, Data.Caliber / 2, PlayerData.ProjLength)
	Data.ProjMass = math.max(GUIData.ProjVolume-PlayerData.Data5, 0) * 7.9 / 1000 + math.min(PlayerData.Data5,GUIData.ProjVolume) * ACF.HEDensity / 1000 + ConeArea * ConeThick * 7.9 / 1000 --Volume of the projectile as a cylinder - Volume of the filler - Volume of the crush cone * density of steel + Volume of the filler * density of TNT + Area of the cone * thickness * density of steel
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)
	local Energy = ACF_Kinetic(Data.MuzzleVel * 39.37 , Data.ProjMass, Data.LimitVel)

	local MaxVol = 0
	MaxVol, MaxLength, MaxRadius = ACF_RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)

	GUIData.MinConeAng = 0
	GUIData.MaxConeAng = math.deg(math.atan((Data.ProjLength - ConeThick ) / (Data.Caliber / 2)))
	Data.ConeAng = math.Clamp(PlayerData.Data6, GUIData.MinConeAng, GUIData.MaxConeAng)
	ConeLength, ConeArea, AirVol = Round.ConeCalc(Data.ConeAng, Data.Caliber / 2, Data.ProjLength)
	local ConeVol = ConeArea * ConeThick

	GUIData.MinFillerVol = 0
	GUIData.MaxFillerVol = math.max(MaxVol - AirVol - ConeVol,GUIData.MinFillerVol)
	GUIData.FillerVol = math.Clamp(PlayerData.Data5,GUIData.MinFillerVol,GUIData.MaxFillerVol)

	Data.FillerMass = GUIData.FillerVol * ACF.HEDensity / 1450
	Data.BoomFillerMass = Data.FillerMass / 3 --manually update function "pierceeffect" with the divisor
	Data.ProjMass = math.max(GUIData.ProjVolume-GUIData.FillerVol- AirVol-ConeVol,0) * 7.9 / 1000 + Data.FillerMass + ConeVol * 7.9 / 1000
	Data.MuzzleVel = ACF_MuzzleVelocity( Data.PropMass, Data.ProjMass, Data.Caliber )

	--Let's calculate the actual HEAT slug
	Data.SlugMass = ConeVol * 7.9 / 1000
	local Rad = math.rad(Data.ConeAng * 0.5)
	Data.SlugCaliber = Data.Caliber - Data.Caliber * (math.sin(Rad) * 0.5 + math.cos(Rad) * 1.5) * 0.5
	Data.SlugMV = (Data.FillerMass * 0.5 * ACF.HEPower * math.sin(math.rad(10 + Data.ConeAng) * 0.5) / Data.SlugMass) ^ ACF.HEATMVScale --keep fillermass/2 so that penetrator stays the same

	local SlugFrArea = 3.1416 * (Data.SlugCaliber * 0.5) * (Data.SlugCaliber * 0.5)
	Data.SlugPenArea = SlugFrArea^ACF.PenAreaMod
	Data.SlugDragCoef = (SlugFrArea / 10000) / Data.SlugMass
	Data.SlugRicochet = 500									--Base ricochet angle (The HEAT slug shouldn't ricochet at all)

	Data.CasingMass = Data.ProjMass - Data.FillerMass - ConeVol * 7.9 / 1000

	--Random bullshit left
	Data.ShovePower = 0.1
	Data.PenArea = Data.FrArea^ACF.PenAreaMod
	Data.DragCoef = (Data.FrArea / 10000) / Data.ProjMass
	Data.LimitVel = 100										--Most efficient penetration speed in m/s
	Data.KETransfert = 0.1									--Kinetic energy transfert to the target for movement purposes
	Data.Ricochet = 60										--Base ricochet angle
	Data.DetonatorAngle = 75
	Data.Crate = Crate

	Data.Detonated = false
	Data.NotFirstPen = false
	Data.CartMass = Data.ProjMass + Data.PropMass

	if SERVER then --Only the crates need this part
		ServerData.Id = PlayerData.Id
		ServerData.Type = PlayerData.Type

		return table.Merge(Data,ServerData)
	end

	if CLIENT then --Only the GUI needs this part
		GUIData = table.Merge(GUIData, Round.getDisplayData(Data))

		return table.Merge(Data, GUIData)
	end
end

function Round.getDisplayData(Data)
	local GUIData = {}

	local SlugEnergy = ACF_Kinetic(Data.MuzzleVel * 39.37 + Data.SlugMV * 39.37 , Data.SlugMass, 999999)
	GUIData.MaxPen = (SlugEnergy.Penetration / Data.SlugPenArea) * ACF.KEtoRHA
	GUIData.BlastRadius = Data.BoomFillerMass ^ 0.33 * 8 --*39.37
	GUIData.Fragments = math.max(math.floor((Data.BoomFillerMass / Data.CasingMass) * ACF.HEFrag), 2)
	GUIData.FragMass = Data.CasingMass / GUIData.Fragments
	GUIData.FragVel = (Data.BoomFillerMass * ACF.HEPower * 1000 / Data.CasingMass / GUIData.Fragments) ^ 0.5

	return GUIData
end

function Round.network(Crate, BulletData)
	ACF.RoundTypes.HEAT.network( Crate, BulletData )
end

function Round.cratetxt(BulletData)
	local DData = Round.getDisplayData(BulletData)

	local Text = {
		"Command Link: ", math.Round(BulletData.MuzzleVel * 4, 1), " m\n",
		"Max Penetration: ", math.floor(DData.MaxPen), " mm\n",
		"Blast Radius: ", math.Round(DData.BlastRadius, 1), " m\n",
		"Blast Energy: ", math.floor(BulletData.BoomFillerMass * ACF.HEPower), " KJ"
	}

	return table.concat(Text)
end

function Round.detonate(_, Bullet, HitPos)
	ACF_HE(HitPos - Bullet.Flight:GetNormalized() * 3, Bullet.BoomFillerMass, Bullet.CasingMass, Bullet.Owner, Bullet.Filter, Bullet.Gun)

	Bullet.Detonated = true
	Bullet.InitTime = CurTime()
	Bullet.FuseLength = 0.005 + 40 / ((Bullet.Flight + Bullet.Flight:GetNormalized() * Bullet.SlugMV * 39.37):Length() * 0.0254)
	Bullet.Pos = HitPos
	Bullet.Flight = Bullet.Flight + Bullet.Flight:GetNormalized() * Bullet.SlugMV * 39.37
	Bullet.DragCoef = Bullet.SlugDragCoef

	Bullet.ProjMass = Bullet.SlugMass
	Bullet.Caliber = Bullet.SlugCaliber
	Bullet.PenArea = Bullet.SlugPenArea
	Bullet.Ricochet = Bullet.SlugRicochet

	local DeltaTime = CurTime() - Bullet.LastThink
	Bullet.StartTrace = Bullet.Pos - Bullet.Flight:GetNormalized() * math.min(ACF.PhysMaxVel * DeltaTime,Bullet.FlightTime * Bullet.Flight:Length())
	Bullet.NextPos = Bullet.Pos + (Bullet.Flight * ACF.Scale * DeltaTime)		--Calculates the next shell position
end

function Round.propimpact(Index, Bullet, Target, HitNormal, HitPos, Bone)
	if ACF_Check( Target ) then
		if Bullet.Detonated then
			Bullet.NotFirstPen = true

			local Speed = Bullet.Flight:Length() / ACF.Scale
			local Energy = ACF_Kinetic(Speed , Bullet.ProjMass, 999999)
			local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal , Bone)

			if HitRes.Overkill > 0 then
				table.insert(Bullet.Filter , Target)					--"Penetrate" (Ingoring the prop for the retry trace)
				ACF_Spall(HitPos , Bullet.Flight , Bullet.Filter , Energy.Kinetic * HitRes.Loss , Bullet.Caliber , Target.ACF.Armour , Bullet.Owner) --Do some spalling
				Bullet.Flight = Bullet.Flight:GetNormalized() * math.sqrt(Energy.Kinetic * (1 - HitRes.Loss) * ((Bullet.NotFirstPen and ACF.HEATPenLayerMul) or 1) * 2000 / Bullet.ProjMass) * 39.37

				return "Penetrated"
			else
				return false
			end
		else
			local Speed = Bullet.Flight:Length() / ACF.Scale
			local Energy = ACF_Kinetic(Speed , Bullet.ProjMass - Bullet.FillerMass, Bullet.LimitVel)
			local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal , Bone)

			if HitRes.Ricochet then
				return "Ricochet"
			else
				Round.detonate(Index, Bullet, HitPos, HitNormal)

				return "Penetrated"
			end
		end
	else
		table.insert(Bullet.Filter , Target)

		return "Penetrated"
	end

	return false
end

function Round.worldimpact(Index, Bullet, HitPos, HitNormal)
	if not Bullet.Detonated then
		Round.detonate(Index, Bullet, HitPos, HitNormal)

		return "Penetrated"
	end

	local Energy = ACF_Kinetic(Bullet.Flight:Length() / ACF.Scale, Bullet.ProjMass, 999999)
	local HitRes = ACF_PenetrateGround(Bullet, Energy, HitPos, HitNormal)

	if HitRes.Penetrated then
		return "Penetrated"
	else
		return false
	end
end

function Round.endflight(Index)
	ACF_RemoveBullet(Index)
end

local DecalIndex = ACF.GetAmmoDecalIndex

function Round.endeffect(Bullet)
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetRadius(Bullet.Caliber)
	Effect:SetDamageType(DecalIndex(Bullet.AmmoType))

	util.Effect("ACF_Impact", Effect)
end

function Round.pierceeffect(Effect, Bullet)
	if Bullet.Detonated then
		local Data = EffectData()
		Data:SetOrigin(Bullet.SimPos)
		Data:SetNormal(Bullet.SimFlight:GetNormalized())
		Data:SetScale(Bullet.SimFlight:Length())
		Data:SetMagnitude(Bullet.RoundMass)
		Data:SetRadius(Bullet.Caliber)
		Data:SetDamageType(DecalIndex(Bullet.AmmoType))

		util.Effect("ACF_Penetration", Data)
	else
		local _, _, BoomFillerMass = Round.CrushCalc(Bullet.SimFlight:Length() * 0.0254, Bullet.FillerMass)
		local Data = EffectData()
		Data:SetOrigin(Bullet.SimPos)
		Data:SetNormal(Bullet.SimFlight:GetNormalized())
		Data:SetRadius(math.max(BoomFillerMass ^ 0.33 * 8 * 39.37, 1))

		util.Effect("ACF_HEAT_Explosion", Data)

		Bullet.Detonated = true

		Effect:SetModel("models/Gibs/wood_gib01e.mdl")
	end
end

function Round.ricocheteffect(Bullet)
	local Detonated = Bullet.Detonated
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetScale(Bullet.SimFlight:Length())
	Effect:SetMagnitude(Bullet.RoundMass)
	Effect:SetRadius(Bullet.Caliber)
	Effect:SetDamageType(DecalIndex(Detonated and Bullet.AmmoType or "AP"))

	util.Effect("ACF_Ricochet", Effect)
end

function Round.guicreate( Panel, Table )
	acfmenupanel:AmmoSelect(ACF.AmmoBlacklist.GLATGM)

	acfmenupanel:CPanelText("BonusDisplay", "")

	acfmenupanel:CPanelText("Desc", "")	--Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "")	--Total round length (Name, Desc)

	--Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("PropLength", 0, 0, 1000, 3, "Propellant Length", "")
	acfmenupanel:AmmoSlider("ProjLength", 0, 0, 1000, 3, "Projectile Length", "")
	acfmenupanel:AmmoSlider("ConeAng", 0, 0, 1000, 3, "HEAT Cone Angle", "")
	acfmenupanel:AmmoSlider("FillerVol", 0, 0, 1000, 3, "Total HEAT Warhead volume", "")

	acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "")			--Tracer checkbox (Name, Title, Desc)

	acfmenupanel:CPanelText("VelocityDisplay", "")	--Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("BlastDisplay", "")	--HE Blast data (Name, Desc)
	acfmenupanel:CPanelText("FragDisplay", "")	--HE Fragmentation data (Name, Desc)

	--acfmenupanel:CPanelText("RicoDisplay", "")	--estimated rico chance
	acfmenupanel:CPanelText("SlugDisplay", "")	--HEAT Slug data (Name, Desc)

	Round.guiupdate(Panel, Table)
end

function Round.guiupdate(Panel)
	local PlayerData = {
		Id = acfmenupanel.AmmoData.Data.id,					--AmmoSelect GUI
		Type = "GLATGM",									--Hardcoded, match ACFRoundTypes table index
		PropLength = acfmenupanel.AmmoData.PropLength,		--PropLength slider
		ProjLength = acfmenupanel.AmmoData.ProjLength,		--ProjLength slider
		Data5 = acfmenupanel.AmmoData.FillerVol,
		Data6 = acfmenupanel.AmmoData.ConeAng,
		Data10 = acfmenupanel.AmmoData.Tracer and 1 or 0,	--Tracer
	}

	local Data = Round.convert(Panel, PlayerData)

	RunConsoleCommand("acfmenu_data1", acfmenupanel.AmmoData.Data.id)
	RunConsoleCommand("acfmenu_data2", PlayerData.Type)
	RunConsoleCommand("acfmenu_data3", Data.PropLength)		--For Gun ammo, Data3 should always be Propellant
	RunConsoleCommand("acfmenu_data4", Data.ProjLength)
	RunConsoleCommand("acfmenu_data5", Data.FillerVol)
	RunConsoleCommand("acfmenu_data6", Data.ConeAng)
	RunConsoleCommand("acfmenu_data10", Data.Tracer)

	acfmenupanel:AmmoSlider("PropLength", Data.PropLength, Data.MinPropLength, Data.MaxTotalLength, 3, "Propellant Length", "Propellant Mass : " .. math.floor(Data.PropMass * 1000) .. " g")	--Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", Data.ProjLength, Data.MinProjLength, Data.MaxTotalLength, 3, "Projectile Length", "Projectile Mass : " .. math.floor(Data.ProjMass * 1000) .. " g")	--Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ConeAng", Data.ConeAng, Data.MinConeAng, Data.MaxConeAng, 0, "Crush Cone Angle", "")	--HE Filler Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol", Data.FillerVol, Data.MinFillerVol, Data.MaxFillerVol, 3, "HE Filler Volume", "HE Filler Mass : " .. math.floor(Data.FillerMass * 1000) .. " g")	--HE Filler Slider (Name, Min, Max, Decimals, Title, Desc)

	acfmenupanel:AmmoCheckbox("Tracer", "Tracer : " .. math.floor(Data.Tracer * 10) / 10 .. "cm\n", "")			--Tracer checkbox (Name, Title, Desc)

	acfmenupanel:CPanelText("Desc", ACF.RoundTypes[PlayerData.Type].desc)	--Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "Round Length : " .. math.floor((Data.PropLength + Data.ProjLength + Data.Tracer) * 100) / 100 .. "/" .. Data.MaxTotalLength .. " cm")	--Total round length (Name, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "Command Link: " .. math.floor(Data.MuzzleVel * ACF.Scale * 4) .. " m")	--Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("BlastDisplay", "Blast Radius : " .. math.floor(Data.BlastRadius * 100) / 100 .. " m")	--Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("FragDisplay", "Fragments : " .. Data.Fragments .. "\n Average Fragment Weight : " .. math.floor(Data.FragMass * 10000) / 10 .. " g \n Average Fragment Velocity : " .. math.floor(Data.FragVel) .. " m/s")	--Proj muzzle penetration (Name, Desc)

	local R1V, R1P = ACF_PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 300)
	R1P = (ACF_Kinetic((R1V + Data.SlugMV) * 39.37, Data.SlugMass, 999999).Penetration / Data.SlugPenArea) * ACF.KEtoRHA
	local R2V, R2P = ACF_PenRanging( Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 800)
	R2P = (ACF_Kinetic((R2V + Data.SlugMV) * 39.37, Data.SlugMass, 999999).Penetration / Data.SlugPenArea) * ACF.KEtoRHA

	acfmenupanel:CPanelText("SlugDisplay", "Penetrator Mass : " .. math.floor(Data.SlugMass * 10000) / 10 .. " g \n Penetrator Caliber : " .. math.floor(Data.SlugCaliber * 100) / 10 .. " mm \n Penetrator Velocity : " .. math.floor(Data.MuzzleVel + Data.SlugMV) .. " m/s \n Penetrator Maximum Penetration : " .. math.floor(Data.MaxPen) .. " mm RHA\n\n300m pen: " .. math.Round(R1P,0) .. "mm @ " .. math.Round(R1V,0) .. " m\\s\n800m pen: " .. math.Round(R2P,0) .. "mm @ " .. math.Round(R2V,0) .. " m\\s\n\nThe range data is an approximation and may not be entirely accurate.")	--Proj muzzle penetration (Name, Desc)
end

ACF.RoundTypes.GLATGM = Round --Set the round properties

ACF.RegisterAmmoDecal("GLATGM", "damage/heat_pen", "damage/heat_rico", function(Caliber) return Caliber * 0.1667 end)