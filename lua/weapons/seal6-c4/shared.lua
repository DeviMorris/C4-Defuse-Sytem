
AddCSLuaFile( "shared.lua" )

SWEP.Author			= "Hoff"
SWEP.Instructions	= ""

SWEP.Category = "CoD Multiplayer"
SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel			= "models/hoff/weapons/c4/c_c4.mdl"
SWEP.WorldModel			= "models/hoff/weapons/c4/w_c4.mdl"
SWEP.ViewModelFOV = 75

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= 5
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo		= "slam"
SWEP.Primary.Delay = 1

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.PrintName			= "C4"
SWEP.Slot				= 4
SWEP.SlotPos			= 1
SWEP.DrawAmmo			= true
SWEP.DrawCrosshair		= true

SWEP.UseHands = true

SWEP.Offset = {
	Pos = {
		Up = 0,
		Right = 7,
		Forward = 3.5,
	},
	Ang = {
		Up = 0,
		Right = 90,
		Forward = 190,
	}
}
function SWEP:DrawWorldModel( )
	if not IsValid( self:GetOwner() ) then
		self:DrawModel( )
		return
	end

	local bone = self:GetOwner():LookupBone( "ValveBiped.Bip01_R_Hand" )
	if not bone then
		self:DrawModel( )
		return
	end

	local pos, ang = self:GetOwner():GetBonePosition( bone )
	pos = pos + ang:Right() * self.Offset.Pos.Right + ang:Forward() * self.Offset.Pos.Forward + ang:Up() * self.Offset.Pos.Up
	ang:RotateAroundAxis( ang:Right(), self.Offset.Ang.Right )
	ang:RotateAroundAxis( ang:Forward(), self.Offset.Ang.Forward )
	ang:RotateAroundAxis( ang:Up(), self.Offset.Ang.Up )

	self:SetRenderOrigin( pos )
	self:SetRenderAngles( ang )

	self:DrawModel()
end

function SWEP:Initialize()
	-- something keeps setting deploy speed to 4, this is a workaround
	self:SetDeploySpeed(1)
end

function SWEP:Deploy()
	-- something keeps setting deploy speed to 4, this is a workaround
	self:SetDeploySpeed(1)

	if not self:GetOwner().C4s or #self:GetOwner().C4s == 0 then
		self:GetOwner().C4s = {}
	end
	timer.Simple(0.3, function()
		if IsValid(self) then
			self:EmitSound("hoff/mpl/seal_c4/bar_selectorswitch.wav", 45)
		end
	end)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetHoldType("Slam")

	return true
end

function SWEP:StartExplosionChain()
	if table.Count(self:GetOwner().C4s) <= 0 then
		return
	end
	local ent = self:GetOwner().C4s[1] -- Get the first entity in the table

	if not IsValid(ent) then
		table.remove(self:GetOwner().C4s, 1)
		self:StartExplosionChain()
		return
	end

	if ent.QueuedForExplode then
		return
	end

	ent.QueuedForExplode = true
	ent.ExplodedViaWorld = false
	ent:DelayedDestroy(true)
end

function SWEP:PrimaryAttack()
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

	timer.Simple(0.1,function()
		if IsValid(self) then
			self:EmitSound("hoff/mpl/seal_c4/c4_click.wav")
		end
	end)

	if SERVER and self:GetOwner():Alive() and self:GetOwner():IsValid() then
		timer.Simple(0.175, function()
			if IsValid(self) then
				self:StartExplosionChain()
			end
		end)
	end

	self:SetNextPrimaryFire(CurTime() + 1.1)

	-- Need to stop insane values from crashing servers
	local ClampedThrowSpeed = math.Clamp(GetConVar("C4_ThrowSpeed"):GetFloat(), 0.25, 10)
	self:SetNextSecondaryFire(CurTime() + (0.8 / ClampedThrowSpeed))
end

hook.Add("PlayerDeath", "SetAllC4sUnowned", function(victim, weapon, killer)
	if IsValid(victim) and victim:IsPlayer() and victim.C4s and #victim.C4s > 0 then
		for k,v in pairs(victim.C4s) do
			victim.C4s[k].ExplodedViaWorld = true
		end
	end
end)

function SWEP:SecondaryAttack()
	if GetConVar("C4_Infinite"):GetInt() == 0 and self:Ammo1() <= 0 then
		return
	end

	self:SendWeaponAnim(ACT_VM_THROW)
	self:GetOwner():SetAnimation(PLAYER_ATTACK1)

	self:EmitSound("hoff/mpl/seal_c4/whoosh_01.wav")
	timer.Simple(0.095, function()
		if not IsValid(self) then
			return
		end
		if SERVER then

			local TargetPosition = self:GetOwner():GetShootPos() + (self:GetOwner():GetRight() * -8) + (self:GetOwner():GetUp() * -1) + (self:GetOwner():GetForward() * 10)

			local model = "models/hoff/weapons/c4/w_c4.mdl"
			util.PrecacheModel(model)

			local TempC4 = ents.Create("prop_physics")
			TempC4:SetModel(model)
			TempC4:SetPos(TargetPosition)
			TempC4:SetCollisionGroup(COLLISION_GROUP_NONE)
			TempC4:Spawn()

			local mins, maxs = TempC4:GetCollisionBounds()

			TempC4:Remove()

			-- Use the mins and maxs vectors to check if there is enough space to spawn another c4
			local tr = util.TraceHull({start = TargetPosition, endpos = TargetPosition, mins = mins, maxs = maxs, mask = MASK_BLOCKLOS})

			-- Check if the trace hit something
			if not self:GetOwner():IsLineOfSightClear(TargetPosition) or tr.Hit then
				TargetPosition = self:GetOwner():EyePos()
			end

			local ent = ents.Create("cod-c4")
			ent:SetPos(Vector(0,0,0))
			ent:SetOwner(self:GetOwner())  -- Disables collision between the C4 and its owner
			ent:SetPos(TargetPosition)
			ent:SetAngles(Angle(1,0,0))
			ent:Spawn()
			ent:SetOwner(self:GetOwner())  -- Disables collision between the C4 and its owner
			ent.C4Owner = self:GetOwner()
			ent.ThisTrigger = self
			ent.ExplodedViaWorld = false
			ent.QueuedForExplode = false
			ent.UniqueExplodeTimer = "ExplodeTimer" .. self:GetOwner():SteamID() .. math.Rand(1, 1000)
			ent:SetNWString("OwnerID", self:GetOwner():SteamID())

			local phys = ent:GetPhysicsObject()

			--phys:SetMass(0.6)

			-- Compensate for the offcenter spawn
			local aimvector = self:GetOwner():GetAimVector()
			local aimangle = aimvector:Angle()
			aimangle:RotateAroundAxis(aimangle:Up(), -1.5)
			aimvector = aimangle:Forward()
			phys:ApplyForceCenter( aimvector * 1500)

			-- The positive z coordinate emulates the spin from a left underhand throw
			local angvel = Vector(0, math.random(-5000,-2000), math.random(-100,-900))
			angvel:Rotate(-1 * ent:EyeAngles())
			angvel:Rotate(Angle(0, self:GetOwner():EyeAngles().y, 0))

			--local angvel = Vector(0, math.random(-5000,-2000), math.random(-100,-900))
			angvel.x = math.Clamp(angvel.x, -1000, 1000)
			angvel.y = math.Clamp(angvel.y, -1000, 1000)
			angvel.z = math.Clamp(angvel.z, -1000, 1000)

			phys:SetAngleVelocity(Vector(math.Clamp(angvel.x, -2000, 2000), math.Clamp(angvel.y, -2000, 2000), math.Clamp(angvel.z, -2000, 2000)))

			table.insert( self:GetOwner().C4s, ent )
			if engine.ActiveGamemode() ~= "nzombies" then
				undo.Create("C4")
					undo.AddEntity(ent)
					undo.SetPlayer(self:GetOwner())
					undo.AddFunction(function(UndoFunc)
						local UndoEnt = UndoFunc.Entities[1]

						-- Check if the entity is still valid
						if UndoEnt:IsValid() then
							-- Remove the entity from the owner's C4s table
							table.RemoveByValue(UndoFunc.Owner.C4s, ent)
						else
							-- The c4 doesn't exist anymore (probably exploded)
							return false
						end
					end)
				undo.Finish()

				self:GetOwner():AddCount("sents", ent) -- Add to the SENTs count ( ownership )
				self:GetOwner():AddCount("my_props", ent) -- Add count to our personal count
				self:GetOwner():AddCleanup("sents", ent) -- Add item to the sents cleanup
				self:GetOwner():AddCleanup("my_props", ent) -- Add item to the cleanup
			end
		end

		if GetConVar("C4_Infinite"):GetInt() == 0 then
			self:GetOwner():RemoveAmmo(1,"slam")
		end
	end)

	self:SetNextPrimaryFire(CurTime() + 1.1)

	-- Need to stop insane values from crashing servers
	local ClampedThrowSpeed = math.Clamp(GetConVar("C4_ThrowSpeed"):GetFloat(), 0.25, 10)
	self:SetNextSecondaryFire(CurTime() + (0.8 / ClampedThrowSpeed))
end

function SWEP:ShouldDropOnDie()
	return false
end

function SWEP:Reload()
	-- First, check if the reload delay has expired
	if self.ReloadDelay and CurTime() < self.ReloadDelay then
		return
	end

	-- Trace a line to a hit location and do a sphere trace from there and sort by distance
	-- We have to do this because GetEyeTrace to a c4 parented to an entity is unreliable
	local trace = util.TraceLine({
		start = self:GetOwner():EyePos(),
		endpos = self:GetOwner():EyePos() + self:GetOwner():EyeAngles():Forward() * 85,
		filter = {self:GetOwner()}
	})
	local hitPos = trace.HitPos
	local c4s = ents.FindInSphere(hitPos, 1)
	table.sort(c4s, function(a, b) return a:GetPos():Distance(hitPos) < b:GetPos():Distance(hitPos) end)
	local hitEnt = nil
	for _, ent in ipairs(c4s) do
		if ent:GetClass() == "cod-c4" then
			hitEnt = ent
			break
		end
	end

	-- Check if the trace hit an entity and if it is a C4 entity
	if IsValid(hitEnt) and hitEnt:GetClass() == "cod-c4" and hitEnt:GetNWString("OwnerID") == self:GetOwner():SteamID() then
		-- Check if the C4 entity is owned by the player
		--if hitEnt:GetNWString("OwnerID") == self:GetOwner():SteamID() then

			if self:GetOwner():EyePos():Distance(hitEnt:GetPos()) > 85 then
				return
			end

			local effectData = EffectData()
			effectData:SetOrigin(hitEnt:GetPos())
			util.Effect("inflator_magic", effectData)

			if SERVER then
				if GetConVar("C4_Infinite"):GetBool() == false then
					-- Give the player one "Slam" ammo
					self:GetOwner():GiveAmmo(1, "Slam")
				end

				-- Remove the C4 entity from the player's C4s array
				if table.HasValue(self:GetOwner().C4s, hitEnt) then
					table.RemoveByValue(self:GetOwner().C4s, hitEnt)
				end

				-- Remove the C4 entity from the world
				hitEnt:Remove()
			--else
				--if self.HasContextAnims then
				--	net.Start("VManip_SimplePlay") 
				--	net.WriteString("use") 
				--	net.Send(self.Owner)
				--end
			end

			-- Set the reload delay so the player cannot reload again for 0.5 seconds
			self.ReloadDelay = CurTime() + 0.5
		--end
	end
end

function SWEP:DoDrawCrosshair(x, y)
	-- Crosshair disabled
	return true
end
