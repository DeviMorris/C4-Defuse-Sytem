
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
include( "sv_diffuse.lua" )

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then
		return
	end
	-- local SpawnPos = tr.HitPos + tr.HitNormal * 16
	local ent = ents.Create( "cod-c4" )
	ent:SetPos( Vector(0,0,0) )
	ent:Spawn()
	ent:Activate()

	ent:SetOwner(ply) -- Disables collision between the C4 and its owner
	return ent
end


function ENT:Initialize()
	self:SetModel( "models/hoff/weapons/c4/w_c4.mdl" )
	self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:DrawShadow(false)

	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
	end

	self.Hit = false

	self.ExplodedViaWorld = false

	self:SetDTFloat( 0, math.Rand( 0.5, 1.3 ) )
	self:SetDTFloat( 1, math.Rand( 0.3, 1.2 ) )

	--self.Entity:SetOwner(self.C4Owner)

	self:SetNWBool("CanUse", false)
end

function ENT:PhysgunPickup(ply, ent)
	if ent:GetClass() == "cod-c4" then
		return false
	end
end
hook.Add("PhysgunPickup", "my_physgun_pickup_hook", function(ply, ent)
	if IsValid(ent) and ent.PhysgunPickup then
		return ent:PhysgunPickup(ply, ent)
	end
end)

function ENT:SetupDataTables()
	self:DTVar( "Float", 0, "RotationSeed1" )
	self:DTVar( "Float", 1, "RotationSeed2" )
end

function ENT:OnRemove()
	-- Check if the C4 owner is valid
	if IsValid(self) and IsValid(self.C4Owner) and IsValid(self.C4Owner.C4s) then
		-- Check if the C4 is in the owner's C4s table
		if table.HasValue(self.C4Owner.C4s, self) then
			-- Remove the C4 from the owner's C4s table
			table.RemoveByValue(self.C4Owner.C4s, self)
		end
	end
end

function ENT:DelayedDestroy(bTriggeredByOwner)
	if !IsValid(self) then
		return
	end
	local LastC4Position = self:GetPos()
	local ExplodedViaWorld = self.ExplodedViaWorld
	self.ExplodedViaWorld = false
	self.QueuedForExplode = true
	local CachedC4s = self.C4Owner.C4s

	-- Set a timer to explode the found C4 entity after a delay of 0.1 seconds
	if self:GetParent() ~= nil then
		self:SetParent()
	end
	timer.Simple(0.1, function()
		if bTriggeredByOwner then
			if IsValid(self) and IsValid(self.C4Owner) then
				-- Index 2 is the next c4 to activate, since index 1 is this one (probably)
				local ent = self.C4Owner.C4s[2]
				while not IsValid(ent) do
					table.remove(self.C4Owner.C4s, 2)
					ent = self.C4Owner.C4s[2]
					if table.Count(self.C4Owner.C4s) < 2 and !IsValid(ent) then
						break
					end
				end
				if IsValid(ent) and IsValid(self) then
					ent.ExplodedViaWorld = false
					ent:DelayedDestroy(true)
				end
				table.remove(self.C4Owner.C4s, 1)
				if table.Count(self.C4Owner.C4s) <= 0 then
					self.C4Owner.C4s = {}
				end
			end
		end

		-- Find all C4 entities within a radius of 128 units from the current C4 entity
		local entities = ents.FindInSphere(LastC4Position, 128)

		-- Sort the entities by distance
		table.sort(entities, function(a, b)
			-- Calculate the distance from the C4 to each entity
			local distanceA = a:GetPos():Distance(LastC4Position)
			local distanceB = b:GetPos():Distance(LastC4Position)

			-- Compare the distances and return the result of the comparison
			return distanceA < distanceB
		end)

		-- Iterate over the sorted entities
		for k, v in pairs(entities) do

			if v ~= self then
				-- Check if the current entity is a C4 entity, is not the current C4 entity, and is valid
				if v:GetClass() == "cod-c4" and v:IsValid() then
					if (ExplodedViaWorld or !table.HasValue(CachedC4s, v)) and v.QueuedForExplode == false then
							
						-- Check if the found C4 entity has an "Explode" function
						if (type(v.Explode) == "function") then
							
							-- Explode the found C4 entity
							--v.ThisTrigger = self.ThisTrigger
							v.ExplodedViaWorld = true
							v:DelayedDestroy(false)
								
						end
						-- Break the loop after finding and exploding the first C4 entity
						break
					end
					break
				end
			end
		end

		-- Explode this c4 and remove it from the array (if it's in there)
		if IsValid(self) then
			if IsValid(self.C4Owner) and table.HasValue(self.C4Owner.C4s, self) then
				table.RemoveByValue(self.C4Owner.C4s, self)
			end
			self:Explode(bTriggeredByOwner)
		end
	end)
end

function ENT:Explode(bTriggeredByOwner)

	self:EmitSound( "ambient/explosions/explode_4.wav" )

	local detonate = ents.Create( "env_explosion" )
		detonate:SetOwner(self.C4Owner)
		detonate:SetPos( self:GetPos() )
		detonate:SetKeyValue( "iMagnitude", GetConVar("C4_Magnitude"):GetString() )
		--detonate:SetKeyValue( "iRadiusOverride", GetConVar("C4_Radius"):GetString() )
		detonate:Spawn()
		detonate:Activate()
		detonate:Fire( "Explode", "", 0 )

	local shake = ents.Create( "env_shake" )
		shake:SetOwner( self:GetOwner() )
		shake:SetPos( self:GetPos() )
		shake:SetKeyValue( "amplitude", "2000" )
		shake:SetKeyValue( "radius", "400" )
		shake:SetKeyValue( "duration", "2.5" )
		shake:SetKeyValue( "frequency", "255" )
		shake:SetKeyValue( "spawnflags", "4" )
		shake:Spawn()
		shake:Activate()
		shake:Fire( "StartShake", "", 0 )

	self.QueuedForExplode = true

	if ConVarExists("C4_KnockDoors") and GetConVar("C4_KnockDoors"):GetBool() then
		self:KnockDownDoors()
	end

	-- Search nearby this exploding c4, if it finds one not in the c4 table, explode it
	self:DelayedDestroy(bTriggeredByOwner)

	self:Remove()
end

function ENT:KnockDownDoors()
	local SearchRadius = ConVarExists("C4_DoorSearchRadius") and GetConVar("C4_DoorSearchRadius"):GetInt() or 100
	local entities = ents.FindInSphere(self:GetPos(), SearchRadius)
	for k, ItDoor in pairs(entities) do
		local DoorClass = ItDoor:GetClass()
		if DoorClass == "func_door" or DoorClass == "func_door_rotating" or DoorClass == "prop_door_rotating" then
			if !ItDoor.KnockedDown then
				self:BlastDoor(ItDoor)
			end
		end
	end
end

function ENT:BlastDoor(FoundDoor)
	FoundDoor.KnockedDown = true
	FoundDoor:Fire("lock","",0)
	FoundDoor:Fire("Open","",0)
	FoundDoor:SetCollisionGroup(COLLISION_GROUP_WORLD)
	FoundDoor:CollisionRulesChanged()
	FoundDoor:SetNoDraw(true)

	FoundDoor.FakeDoor = ents.Create("prop_physics")
	FoundDoor.FakeDoor:SetModel(FoundDoor:GetModel())
	FoundDoor.FakeDoor:SetPos(FoundDoor:GetPos())
	FoundDoor.FakeDoor:SetAngles(FoundDoor:GetAngles())
	FoundDoor.FakeDoor:Spawn()
	FoundDoor.FakeDoor:Activate()
	if FoundDoor:GetSkin() then
		FoundDoor.FakeDoor:SetSkin(FoundDoor:GetSkin())
	end

	local phys = FoundDoor.FakeDoor:GetPhysicsObject()
	if IsValid(phys) then
		local KnockStrength = ConVarExists("C4_DoorKnockStrength") and GetConVar("C4_DoorKnockStrength"):GetFloat() or 500
		KnockStrength = KnockStrength * -1
		phys:ApplyForceOffset((self:GetAngles():Up() * KnockStrength) * phys:GetMass(), self:GetPos())
	end
end

ENT.PhysData = nil
ENT.PhysRef = nil
function ENT:PhysicsCollide(data, phys)
	if data.HitEntity:GetClass() == "cod-c4" or data.HitEntity == self.C4Owner then return end

	if self:IsValid() and !self.Hit then
		-- Check if owner is looking at the hit position
		local bShouldStick = false
		if IsValid(self.C4Owner) then
			local ownerAimDir = self.C4Owner:GetAimVector()
			local toHitDir = (data.HitPos - self.C4Owner:EyePos()):GetNormalized()
			local dotProduct = ownerAimDir:Dot(toHitDir)
			
			-- Only stick if player is aiming at the surface (dot > 0.7 means roughly looking at it)
			if dotProduct > 0.7 then
				bShouldStick = true
			end
		end

		if bShouldStick then
			self:EmitSound("hoff/mpl/seal_c4/satchel_plant.wav")
			
			self.ChangeCollisionGroup = true
			timer.Simple(0, function()
				if self.ChangeCollisionGroup then
					self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
					self.ChangeCollisionGroup = false

					local bHitValidEntity = IsValid(data.HitEntity)
					if bHitValidEntity then
						local bHitWorld = data.HitEntity:IsWorld()
						local bHitAnotherC4 = data.HitEntity:GetClass() == "cod-c4"
						local bHitAnNPC = data.HitEntity:IsNPC()
						local bHitAPlayer = data.HitEntity:IsPlayer()
						if bHitValidEntity and !bHitWorld and !bHitAnotherC4 and !bHitAnNPC and !bHitAPlayer then
							self:SetSolid(SOLID_VPHYSICS)
							self:SetMoveType(MOVETYPE_NONE)
							self:SetParent(data.HitEntity)
							self.Stuck = true
							self.Hit = true
						elseif bHitWorld then
							self:SetMoveType(MOVETYPE_NONE)
							self.Stuck = true
							self.Hit = true
						end
					else
						self:SetMoveType(MOVETYPE_NONE)
						self.Stuck = true
						self.Hit = true
					end
					self:SetNWBool("CanUse", true)

					if IsValid(phys) then
						local angVel = phys:GetAngleVelocity()
						local maxAngVel = 1000
						if angVel:Length() > maxAngVel then
							angVel = angVel:GetNormalized() * maxAngVel
							phys:SetAngleVelocity(angVel)
						end
					end

					local HitAngle = data.HitNormal:Angle()
					HitAngle.p = HitAngle.p + 270

					self:SetPos(data.HitPos + ((data.HitNormal / 5) * -11))

					-- Generate a random yaw angle between -60 and 60 degrees
					local yaw = math.random(-60, 60)

					self:SetAngles(HitAngle)
					-- Rotate the Angle object around the entity's up vector using the RotateAroundAxis function
					HitAngle:RotateAroundAxis(self:GetUp(), yaw)
					-- Set the entity's angles to the rotated angles
					self:SetAngles(HitAngle)
					self:SetOwner(nil)
				end
			end)
			self:SetNWBool("Hit", true)
			self.Hit = true
		end
		
		self.PhysData = data
		self.PhysRef = phys
	end
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )

	-- Check if the attacker is not the owner of the C4, or if the damage type is not blast damage
	if dmginfo:GetDamageType() ~= DMG_BLAST then
		self.ExplodedViaWorld = true
		self:Explode(false)
	end
end

function ENT:Touch(ent)
	if ent == self.C4Owner or ent == self.ThisTrigger or ent == self:GetOwner() then
		return false
	end
	if IsValid(ent) and !self.Stuck then
		if ent:IsNPC() || (ent:IsPlayer() && ent != self:GetOwner()) || ent:IsVehicle() then
			self:SetSolid(SOLID_VPHYSICS)
			self:SetMoveType(MOVETYPE_NONE)
			self:SetParent(ent)
			self.Stuck = true
			self.Hit = true
			self:SetOwner(nil)
		end
	end
end
--[[
ENT.CanUse = true
function ENT:Use( activator, caller )
	if activator:IsPlayer() and self.CanUse and self:GetNWString("OwnerID") == activator:SteamID() then
		self.CanUse = false
		if SERVER then
			if GetConVar("C4_Infinite"):GetBool() == false then
				if activator:HasWeapon("seal6-c4") then
					activator:EmitSound("hoff/mpl/seal_c4/ammo.wav")
					activator:GiveAmmo(1, "Slam", true)
				else
					activator:Give("seal6-c4")
					activator:SelectWeapon("seal6-c4")
					activator:RemoveAmmo(4, "Slam")
				end
			end
			table.RemoveByValue( activator.C4s, self )
			self:Remove()
		end
	end
end
]]