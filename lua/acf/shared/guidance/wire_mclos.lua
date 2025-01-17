local Guidance = ACF.RegisterGuidance("Wire (MCLOS)", "Radio (MCLOS)")
local SnapSound = "physics/metal/sawblade_stick%s.wav"

Guidance.desc = "This guidance package allows you to manually control the direction of the missile."

function Guidance:Configure(Missile)
	Guidance.BaseClass.Configure(self, Missile)

	self.WireLength = 31496 * 31496 -- Missile.WireLength * Missile.WireLength or 31496
end

function Guidance:OnLaunched(Missile)
	Guidance.BaseClass.OnLaunched(self, Missile)

	self.Rope = constraint.CreateKeyframeRope(Vector(), 0.1, "cable/cable2", nil, self.Source, self.InPos, 0, Missile, self.OutPos, 0)
	self.Rope:SetKeyValue("Width", 0.1)
end

function Guidance:OnRange(Missile)
	local From = self.Source:LocalToWorld(self.InPos)
	local To = Missile:LocalToWorld(self.OutPos)

	return From:DistToSqr(To) <= self.WireLength
end

function Guidance:SnapRope(Missile)
	if not Missile.Launched then return end
	if self.WireSnapped then return end

	self.WireSnapped = true

	if IsValid(self.Rope) then
		self.Rope:Remove()
		self.Rope = nil
	end

	if IsValid(self.Source) then
		self.Source:EmitSound(string.format(SnapSound, math.random(3)))
	end
end

function Guidance:GetGuidance(Missile)
	local Computer = self:GetComputer()

	if not IsValid(Computer) then return {} end
	if self.WireSnapped then return {} end

	if not (self:OnRange(Missile) and self:CheckLOS(Missile)) then
		self:SnapRope(Missile)

		return {}
	end

	if not Computer.Active then return {} end

	local Source = self.Source
	local Elevation = Source.Elevation
	local Azimuth = Source.Azimuth

	if Elevation == 0 and Azimuth == 0 then return {} end

	local Direction = Angle(Elevation, Azimuth):Forward() * 12000

	return { TargetPos = Missile:LocalToWorld(Direction) }
end

function Guidance:OnRemoved(Missile)
	self:SnapRope(Missile)
end

function Guidance:GetDisplayConfig()
	return {
		["Wire Length"] = math.Round(self.WireLength ^ 0.5 * 0.0254, 2) .. " meters"
	}
end