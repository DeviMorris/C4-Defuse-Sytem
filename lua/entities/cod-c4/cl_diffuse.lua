-- мг обрезвреж.

-- переменные
local isActive = false
local targetC4 = nil
local wireState = 0 -- 0 = стандарт, 1 = красный, 2 = коричневый, 3 = оба
local animFrame = 0
local isAnimating = false
local animStartTime = 0
local resultMsg = ""
local resultTime = 0
local isHovering = false 
local isHintPlaying = false
local hintSound = nil
local openTime = 0

-- материалы
local matBombNormal = Material("models/hoff/weapons/c4/mg/bombs/bomb_normal.png", "smooth")
local matBombRed = Material("models/hoff/weapons/c4/mg/bombs/bomb_red_cut.png", "smooth")
local matBombBrown = Material("models/hoff/weapons/c4/mg/bombs/bomb_brown_cut.png", "smooth")
local matBombBoth = Material("models/hoff/weapons/c4/mg/bombs/bomb_both_cut.png", "smooth")
local matPliers = {}
for i = 1, 10 do
	matPliers[i] = Material("models/hoff/weapons/c4/mg/anims/pliers_" .. i .. ".png", "smooth")
end
local matPliersCursor = Material("models/hoff/weapons/c4/mg/pliers_cursor.png", "smooth")
local matScissors = Material("models/hoff/weapons/c4/mg/scissors.png", "noclamp smooth mips")

local BOMB_W = 1032
local BOMB_H = 1080
local WIRE_RED_X = 511
local WIRE_RED_Y = 219
local WIRE_BROWN_X = 605
local WIRE_BROWN_Y = 227

local function GetLookingAtC4()
	local ply = LocalPlayer()
	local trace = util.TraceLine({
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:EyeAngles():Forward() * 100,
		filter = ply
	})
	
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "cod-c4" then
		return trace.Entity
	end
	
	return nil
end


local function OpenDiffuseGame(c4)
	isActive = true
	targetC4 = c4
	wireState = 0
	animFrame = 0
	isAnimating = false
	openTime = CurTime()
	gui.EnableScreenClicker(false )

	timer.Simple(2, function()
        if isActive then
            gui.EnableScreenClicker(true)
        end
    end)
    local sounds = {
        "hoff/mpl/seal_c4/stand/red_1.wav",
        "hoff/mpl/seal_c4/stand/red_2.wav"
    }
    surface.PlaySound(sounds[math.random(#sounds)])
	net.Start("C4_FreezePlayer")
    net.WriteBool(true)
    net.SendToServer()
end


local function CloseDiffuseGame()
    isActive = false
    targetC4 = nil
    wireState = 0
    animFrame = 0
    isAnimating = false
    resultMsg = ""
    isHovering = false
    isHintPlaying = false
    hintSound = nil
    
    gui.EnableScreenClicker(false)
    
    net.Start("C4_FreezePlayer")
    net.WriteBool(false)
    net.SendToServer()
end

-- логика
hook.Add("Think", "C4_DiffuseMinigameThink", function()
	local ply = LocalPlayer()
	
	if not IsValid(ply) or not ply:Alive() then
		if isActive then
			CloseDiffuseGame()
		end
		return
	end
	
	local has_diffuse = false
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep:GetClass() == "seal6-diffuse" then
		has_diffuse = true
	end
	
	if input.IsKeyDown(KEY_E) and not isActive and has_diffuse then
		local c4 = GetLookingAtC4()
		if IsValid(c4) then
			OpenDiffuseGame(c4)
		end
	end
	
	if isActive then
		if not IsValid(targetC4) or not has_diffuse then
			CloseDiffuseGame()
		end
	end

	if isAnimating then
		local elapsed = CurTime() - animStartTime
		local fps = 24
		local frame_time = 1 / fps
		animFrame = math.floor(elapsed / frame_time) + 1
		
		if animFrame > 10 then
			isAnimating = false
			animFrame = 0
		end
	end
end)


local function IsClickInZone(mx, my, zone_x, zone_y, zone_size)
	local half = zone_size / 2
	return mx >= zone_x - half and mx <= zone_x + half and my >= zone_y - half and my <= zone_y + half
end

-- клик
hook.Add("GUIMousePressed", "C4_DiffuseMinigameClick", function(mouseCode)
	if not isActive then
		return
	end
	
	if mouseCode == MOUSE_LEFT then
		if not isAnimating then
			local mx, my = gui.MousePos()
			local scrw = ScrW()
			local scrh = ScrH()
			local cx = scrw / 2
			local cy = scrh / 2
			
			local scale = (scrh * 0.8) / BOMB_H
			local bomb_width = BOMB_W * scale
			local bomb_height = BOMB_H * scale
			local bomb_x = cx - bomb_width / 2
			local bomb_y = cy - bomb_height / 2
			
			local red_x = bomb_x + (WIRE_RED_X * scale)
			local red_y = bomb_y + (WIRE_RED_Y * scale)
			local brown_x = bomb_x + (WIRE_BROWN_X * scale)
			local brown_y = bomb_y + (WIRE_BROWN_Y * scale)
			local scissors_size = 357 * scale
			
			if IsClickInZone(mx, my, red_x, red_y, scissors_size) then
				if wireState == 0 then
					wireState = 1 
					isAnimating = true
					animStartTime = CurTime()
					animFrame = 1
				end
				return
			end
			
			if IsClickInZone(mx, my, brown_x, brown_y, scissors_size) then
				if wireState == 0 then
					wireState = 2
					resultMsg = "НЕ ТОТ ПРОВОД БЛzТЬ\nВЗРЫВ ЧЕРЕЗ 2 СЕКУНДЫ"
					resultTime = CurTime()
					
					if hintSound then
						LocalPlayer():StopSound(hintSound)
						hintSound = nil
					end
					isHintPlaying = false
					isHovering = false
					
					isAnimating = true
					animStartTime = CurTime()
					animFrame = 1
                    local sound_fails = {
                        "hoff/mpl/seal_c4/fail/pizda.wav",
                        "hoff/mpl/seal_c4/fail/pizda2.wav",
                        "hoff/mpl/seal_c4/fail/pizda3.wav",
                        "hoff/mpl/seal_c4/fail/pizda4.wav",
                        "hoff/mpl/seal_c4/fail/pizda5.wav"
                    }
					surface.PlaySound(sound_fails[math.random(#sound_fails)])
					local cached_c4 = targetC4
					
					timer.Simple(2, function()
						if IsValid(cached_c4) then
							net.Start("C4_DiffuseFailed")
							net.WriteEntity(cached_c4)
							net.SendToServer()
						end
						CloseDiffuseGame()
						resultMsg = ""
					end)
					
					return
				elseif wireState == 1 then
					wireState = 3
					resultMsg = "УСПЕШНО!"
					resultTime = CurTime()
					
					isAnimating = true
					animStartTime = CurTime()
					animFrame = 1
					surface.PlaySound("hoff/mpl/seal_c4/stand/krasava_1.wav")
					local cached_c4 = targetC4
					
					timer.Simple(1, function()
						if IsValid(cached_c4) then
							net.Start("C4_Diffused")
							net.WriteEntity(cached_c4)
							net.SendToServer()
						end
						CloseDiffuseGame()
						resultMsg = ""
					end)
					
					return
				end
			end
		end
	end
end)

hook.Add("HUDPaint", "C4_DiffuseMinigameHUD", function()
	local ply = LocalPlayer()
	
	if not IsValid(ply) or not ply:Alive() then
		return
	end
	
	local scrw = ScrW()
	local scrh = ScrH()
	local cx = scrw / 2
	local cy = scrh / 2
	
	local has_diffuse = false
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep:GetClass() == "seal6-diffuse" then
		has_diffuse = true
	end
	
	if not isActive then
		local c4 = GetLookingAtC4()
		
		if IsValid(c4) and has_diffuse then
			draw.SimpleText("PRESS E TO DIFFUSE", "DiffuseFont", cx, cy + 100, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		
		if IsValid(c4) and not has_diffuse then
			draw.SimpleText("NEED DIFFUSE KIT", "DiffuseFont", cx, cy + 100, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		
		return
	end
	
	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(0, 0, scrw, scrh)
	
	local scale = (scrh * 0.8) / BOMB_H
	local bomb_width = BOMB_W * scale
	local bomb_height = BOMB_H * scale
	local bomb_x = cx - bomb_width / 2
	local bomb_y = cy - bomb_height / 2
	
	surface.SetDrawColor(255, 255, 255, 255)
	
	if wireState == 0 then
		surface.SetMaterial(matBombNormal)
	elseif wireState == 1 then
		surface.SetMaterial(matBombRed)
	elseif wireState == 2 then
		surface.SetMaterial(matBombBrown)
	elseif wireState == 3 then
		surface.SetMaterial(matBombBoth)
	end
	
	surface.DrawTexturedRect(bomb_x, bomb_y, bomb_width, bomb_height)
	
	if resultMsg ~= "" then
		local color = Color(255, 255, 255)
		local is_error = string.find(resultMsg, "БЛzТЬ")
		
		if is_error then
			color = Color(255, 50, 50)
			-- две строки
			draw.SimpleText("НЕ ТОТ ПРОВОД БЛzТЬ", "DiffuseResultFont", cx, cy - 40, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("ВЗРЫВ ЧЕРЕЗ 2 СЕКУНДЫ", "DiffuseResultFont", cx, cy + 40, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			color = Color(50, 255, 50)
			draw.SimpleText(resultMsg, "DiffuseResultFont", cx, cy, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
	
	local red_x = bomb_x + (WIRE_RED_X * scale)
	local red_y = bomb_y + (WIRE_RED_Y * scale)
	local scissors_size = 40 * scale
	
	if wireState ~= 1 and wireState ~= 3 then
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(matScissors)
		surface.DrawTexturedRect(red_x - scissors_size / 2, red_y - scissors_size / 2, scissors_size, scissors_size)
	end
	
	local brown_x = bomb_x + (WIRE_BROWN_X * scale)
	local brown_y = bomb_y + (WIRE_BROWN_Y * scale)
	
	if wireState ~= 2 and wireState ~= 3 then
		if wireState == 0 then
			surface.SetDrawColor(255, 255, 255, 90)
		elseif wireState == 1 then
			surface.SetDrawColor(255, 255, 255, 255)
		end
		surface.SetMaterial(matScissors)
		surface.DrawTexturedRect(brown_x - scissors_size / 2, brown_y - scissors_size / 2, scissors_size, scissors_size)
	end
	if CurTime() - openTime >= 2 then
        local mx, my = gui.MousePos()
        local cursor_width = 384
        local cursor_height = 216
        
        surface.SetDrawColor(255, 255, 255, 255)
        if wireState == 0 and resultMsg == "" then
            local mx,my = gui.MousePos()

            if IsClickInZone(mx,my,brown_x+100,brown_y,30) then
                if not isHovering and not isHintPlaying then
                    isHovering = true 
                    isHintPlaying = true
                    local sounds_gluhoi = {
                        "hoff/mpl/seal_c4/stand/gluhoi_1.wav",
                        "hoff/mpl/seal_c4/stand/gluhoi_2.wav",
                        "hoff/mpl/seal_c4/stand/gluhoi_3.wav",
                        "hoff/mpl/seal_c4/stand/gluhoi_4.wav",
                        "hoff/mpl/seal_c4/stand/gluhoi_5.wav"
                    }
                    hintSound = sounds_gluhoi[math.random(#sounds_gluhoi)]
                    surface.PlaySound(hintSound)
                    timer.Simple(3, function()
                        isHintPlaying = false
                    end)
                end
            else
                isHovering = false 
            end
        end
        if isAnimating and animFrame > 0 and animFrame <= 10 then
            surface.SetMaterial(matPliers[animFrame])
        else
            surface.SetMaterial(matPliersCursor)
        end
        surface.DrawTexturedRect(mx - cursor_width / 2, my - cursor_height / 2, cursor_width, cursor_height)
    end
end)
hook.Add("InputMouseApply", "C4_DiffuseBlockMouse", function(cmd, x, y, ang)
		if isActive then
			cmd:SetViewAngles(ang)
			return true
		end
end)
hook.Add("SetupMove", "C4_DiffuseBlockMove", function(ply, mv, cmd)
		if isActive and ply == LocalPlayer() then
			mv:SetForwardSpeed(0) 
			mv:SetSideSpeed(0)
			mv:SetUpSpeed(0)
			return true
		end
end)

surface.CreateFont("DiffuseFont", {
	font = "Arial",
	size = 30,
	weight = 700
})

surface.CreateFont("DiffuseResultFont", {
	font = "Arial",
	size = 60,
	weight = 900
})