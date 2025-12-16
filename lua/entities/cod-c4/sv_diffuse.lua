-- обрезвреж.

util.AddNetworkString("C4_Diffused")
util.AddNetworkString("C4_DiffuseFailed")
util.AddNetworkString("C4_FreezePlayer")
-- успехъ
net.Receive("C4_Diffused", function(len, ply)
	local c4 = net.ReadEntity()
	
	if not IsValid(c4) then
		return
	end
	
	if not IsValid(ply) then
		return
	end
	
	local dist = ply:GetPos():Distance(c4:GetPos())
	if dist > 150 then
		return
	end
	
	if IsValid(c4.C4Owner) and c4.C4Owner.C4s then
		table.RemoveByValue(c4.C4Owner.C4s, c4)
	end
	
	c4:Remove()

	ply:EmitSound("buttons/button14.wav")
end)

-- провал
net.Receive("C4_DiffuseFailed", function(len, ply)
	local c4 = net.ReadEntity()
	
	if not IsValid(c4) then
		return
	end
	
	if not IsValid(ply) then
		return
	end

	c4:Explode(false)
end)


net.Receive("C4_FreezePlayer", function(len, ply)
    local freeze = net.ReadBool()
    
    if not IsValid(ply) then
        return
    end
    
    ply:Freeze(freeze)
end)
