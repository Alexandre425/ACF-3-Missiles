--define the class
ACF_defineGunClass("FGL", {
	spread = 1.5,
	name = "Flare Launcher",
	desc = "Flare Launchers can fire flares much more rapidly than other launchers, but can't load any other ammo types.",
	muzzleflash = "gl_muzzleflash_noscale",
	rofmod = 0.6,
	sound = "acf_missiles/missiles/flare_launch.mp3",
	soundDistance = " ",
	soundNormal = " ",

	ammoBlacklist   = {"AP", "APHE", "FL", "HE", "HEAT", "HP", "SM"} -- ok fun's over
} )

--add a gun to the class
ACF_defineGun("40mmFGL", { --id
	name = "40mm Flare Launcher",
	desc = "Put on an all-American fireworks show with this flare launcher: high fire rate, low distraction rate.  Fill the air with flare.  Careful of your reload time.",
	model = "models/missiles/blackjellypod.mdl",
	gunclass = "FGL",
	caliber = 4.0,
	weight = 75,
	magsize = 30,
	magreload = 20,
	Cyclic = 300,
	year = 1970,
	round = {
		maxlength = 9,
		propweight = 0.007
	}
})
