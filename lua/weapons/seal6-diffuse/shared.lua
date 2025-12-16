AddCSLuaFile( "shared.lua" )

SWEP.Author			= "Hoff"
SWEP.Instructions	= "Обезвреживает C4"

SWEP.Category = "CoD Multiplayer"
SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel			= "models/weapons/c_crowbar.mdl"
SWEP.WorldModel			= "models/weapons/w_crowbar.mdl"
SWEP.ViewModelFOV = 75

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo		= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.PrintName			= "Дифуза"
SWEP.Slot				= 4
SWEP.SlotPos			= 2
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= true

SWEP.UseHands = true

function SWEP:Initialize()
	self:SetHoldType("normal")
end

function SWEP:Deploy()
	self:SetHoldType("normal")
	return true
end

function SWEP:PrimaryAttack()
	-- ничего не делает
end

function SWEP:SecondaryAttack()
	-- ничего не делает
end

function SWEP:Reload()
	-- ничего не делает
end

function SWEP:ShouldDropOnDie()
	return false
end
