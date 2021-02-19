
ACF.RegisterMissileClass("UAR", {
	Name		= "Unguided Aerial Rockets",
	Description	= "Rockets which fit in racks, useful for rocket artillery.",
	Sound		= "acf_missiles/missiles/missile_rocket.mp3",
	Effect		= "Rocket Motor",
	Spread		= 0.2,
	Blacklist	= { "AP", "APHE", "HP", "FL", "SM" }
})

ACF.RegisterMissile("RS82 ASR", "UAR", {
	Name		= "RS-82 Rocket",
	Description	= "A small, unguided rocket, often used in multiple-launch artillery as well as for attacking pinpoint ground targets.",
	Model		= "models/missiles/rs82.mdl",
	Caliber		= 82,
	Mass		= 7,
	Length		= 60,
	Diameter	= 2.2 * 25.4, -- in mm
	ReloadTime	= 5,
	Offset		= Vector(1, 0, 0),
	Year		= 1933,
	Racks		= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true },
	Guidance	= { Dumb = true },
	Fuzes		= { Contact = true, Timed = true },
	ArmDelay	= 0.3,
	Bodygroups = {
		warhead = {
			DataSource = function(Entity)
				return Entity.BulletData and Entity.BulletData.Type
			end,
			HE = {
				OnRack = "HE.smd",
			},
			HEAT = {
				OnRack = "HEAT.smd",
			}
		}
	},
	Round = {
		Model			= "models/missiles/rs82.mdl",
		MaxLength		= 60,
		Armor			= 5,
		PropMass		= 2.5,
		Thrust			= 40000,	-- in kg*in/s^2
		FuelConsumption = 0.08,		-- in g/s/f
		StarterPercent	= 0.15,
		MinSpeed		= 6000,
		DragCoef		= 0.001,
		FinMul			= 0.01,
		TailFinMul		= 0.05,
		PenMul			= math.sqrt(7),
		ActualLength 	= 60,
		ActualWidth		= 8.2
	},
})

ACF.RegisterMissile("HVAR ASR", "UAR", {
	Name		= "HVAR Rocket",
	Description	= "A medium, unguided rocket. More bang than the RS82, at the cost of size and weight.",
	Model		= "models/missiles/hvar.mdl",
	Caliber		= 127,
	Mass		= 64,
	Length		= 173,
	Diameter	= 4 * 25.4, -- in mm
	ReloadTime	= 10,
	Offset		= Vector(2, 0, 0),
	Year		= 1933,
	Racks		= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true, ["3xUARRK"] = true, ["4xRK"] = true },
	Guidance	= { Dumb = true },
	Fuzes		= { Contact = true, Timed = true },
	ArmDelay	= 0.3,
	Round = {
		Model			= "models/missiles/hvar.mdl",
		RackModel		= "models/missiles/hvar_folded.mdl",
		MaxLength		= 173,
		Armor			= 5,
		PropMass		= 16,
		Thrust			= 270000,	-- in kg*in/s^2
		FuelConsumption = 0.053,	-- in g/s/f
		StarterPercent	= 0.15,
		MinSpeed		= 5000,
		DragCoef		= 0.005,
		FinMul			= 0.01,
		TailFinMul		= 0.075,
		PenMul			= math.sqrt(3.95),
		ActualLength 	= 173,
		ActualWidth		= 12.7
	},
})

ACF.RegisterMissile("SPG-9 ASR", "UAR", {
	Name		= "SPG-9 Rocket",
	Description	= "A recoilless rocket launcher similar to an RPG or Grom.",
	Model		= "models/munitions/round_100mm_mortar_shot.mdl",
	Caliber		= 73,
	Mass		= 5,
	Length		= 100,
	Year		= 1962,
	ReloadTime	= 10,
	Racks		= { ["1x SPG9"] = true },
	Guidance	= { Dumb = true },
	Fuzes		= { Contact = true, Optical = true },
	ArmDelay	= 0.05,
	Round = {
		Model			= "models/missiles/glatgm/9m112f.mdl",
		RackModel		= "models/munitions/round_100mm_mortar_shot.mdl",
		MaxLength		= 100,
		Armor			= 5,
		PropMass		= 2,
		Thrust			= 300000,	-- in kg*in/s^2
		FuelConsumption = 0.019,		-- in g/s/f
		StarterPercent	= 0.95,
		MinSpeed		= 900,
		DragCoef		= 0.005,
		FinMul			= 0.002,
		TailFinMul		= 0.02,
		PenMul			= math.sqrt(5.6),
		ActualLength 	= 100,
		ActualWidth		= 7.3
	},
})

ACF.RegisterMissile("S-24 ASR", "UAR", {
	Name		= "S-24 Rocket",
	Description	= "A big, unguided rocket. Mostly used by late cold war era attack planes and helicopters.",
	Model		= "models/missiles/s24.mdl",
	Caliber		= 240,
	Mass		= 235,
	Length		= 233,
	Diameter	= 8.3 * 25.4, -- in mm
	ReloadTime	= 20,
	Year		= 1960,
	Racks		= { ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true },
	Guidance	= { Dumb = true },
	Fuzes		= { Contact = true, Timed = true },
	SkinIndex	= { HEAT = 0, HE = 1 },
	ArmDelay	= 0.3,
	Round = {
		Model			= "models/missiles/s24.mdl",
		MaxLength		= 233,
		Armor			= 5,
		PropMass		= 70,
		Thrust			= 2000000,	-- in kg*in/s^2
		FuelConsumption = 0.052,	-- in g/s/f
		StarterPercent	= 0.15,
		MinSpeed		= 10000,
		DragCoef		= 0.01,
		FinMul			= 0.1,
		TailFinMul		= 0.3,
		PenMul			= math.sqrt(5),
		ActualLength 	= 233,
		ActualWidth		= 24
	},
})

ACF.RegisterMissile("RW61 ASR", "UAR", {
	Name		= "Raketenwerfer 61",
	Description	= "A heavy, demolition-oriented rocket-assisted mortar, devastating against field works but takes a very long time to load.",
	Model		= "models/missiles/RW61M.mdl",
	Caliber		= 380,
	Mass		= 476,
	Length		= 150,
	Year		= 1960,
	ReloadTime	= 40,
	Racks		= { ["380mmRW61"] = true },
	Guidance	= { Dumb = true },
	Fuzes		= { Contact = true, Optical = true },
	SeekCone	= 35,
	ViewCone	= 55,
	Agility		= 1,
	ArmDelay	= 0.5,
	Round = {
		Model			= "models/missiles/RW61M.mdl",
		RackModel		= "models/missiles/RW61M.mdl",
		MaxLength		= 150,
		Armor			= 5,
		PropMass		= 70,
		Thrust			= 500000,	-- in kg*in/s^2
		FuelConsumption = 0.048,		-- in g/s/f
		StarterPercent	= 0.2,
		MinSpeed		= 1,
		DragCoef		= 0.02,
		FinMul			= 0,
		TailFinMul		= 10,
		PenMul			= math.sqrt(2),
		ActualLength 	= 150,
		ActualWidth		= 38
	},
})
