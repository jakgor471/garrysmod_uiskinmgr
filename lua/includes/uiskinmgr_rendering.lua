uiskinmgr = uiskinmgr or {}

//RT_SIZE_OFFSCREEN is very important!!!!!!!!!!!!!
local rt = GetRenderTargetEx("uiskinmgr_rendertarget", 2048, 2048, RT_SIZE_OFFSCREEN, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(1, 256), 0, IMAGE_FORMAT_BGRA8888)
local rt2 = GetRenderTargetEx("uiskinmgr_rendertarget_helper", 2048, 2048, RT_SIZE_OFFSCREEN, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(1, 256), 0, IMAGE_FORMAT_BGRA8888)

local matblurx = Material("pp/blurx")
local matblury = Material("pp/blury")

local operations = {}
operations["Colorize"] = function(currentRT, data)
	if data.mode == "Add" then
		render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ZERO, BLEND_ONE, BLENDFUNC_MIN)
		surface.SetDrawColor( data.color.r, data.color.g, data.color.b, 255 )
		surface.DrawRect(0, 0, ScrW(), ScrH())
		render.OverrideBlend(false)
	elseif data.mode == "Mul" then
		render.OverrideBlend(true, BLEND_DST_COLOR, BLEND_ZERO, BLENDFUNC_ADD, BLEND_ZERO, BLEND_ONE, BLENDFUNC_MIN)
		surface.SetDrawColor( data.color.r, data.color.g, data.color.b, 255 )
		surface.DrawRect(0, 0, ScrW(), ScrH())
		render.OverrideBlend(false)
	end
end
operations["Opacity"] = function(currentRT, data)
	render.OverrideBlend(true, BLEND_ZERO, BLEND_ONE, BLENDFUNC_ADD, BLEND_ONE, BLEND_ONE, BLENDFUNC_MIN)
	surface.SetDrawColor( 0, 0, 0, data.value * 255 )
	surface.DrawRect(0, 0, ScrW(), ScrH())
	render.OverrideBlend(false)
end
operations["BlurX"] = function(currentRT, data)
	render.CopyTexture(currentRT, rt2)

	matblurx:SetTexture("$basetexture", rt2)
	matblurx:SetFloat("$size", data.value * 3)

	render.Clear(0,0,0,0)
	render.SetMaterial(matblurx)
	render.DrawScreenQuad()
end
operations["BlurY"] = function(currentRT, data)
	render.CopyTexture(currentRT, rt2)

	matblury:SetTexture("$basetexture", rt2)
	matblury:SetFloat("$size", data.value * 3)

	render.Clear(0,0,0,0)
	render.SetMaterial(matblury)
	render.DrawScreenQuad()
end
operations["Pixelize"] = function(currentRT, data, orgMat)
	local orgText = orgMat:GetTexture("$basetexture")
	orgMat:SetTexture("$basetexture", rt2)

	local w = orgText:Width()
	local h = orgText:Height()
	local ratio = data.value / 1
	render.PushRenderTarget(rt2, 0, 0, w * ratio, h * ratio)
	render.Clear(0,0,0,0)
	render.ClearDepth()

	surface.SetMaterial(orgMat)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRectUV( 0, 0, ScrW(), ScrH(), 0, 0, 1, 1)

	render.PopRenderTarget()

	render.Clear(0,0,0,0)
	render.SetMaterial(orgMat)
	render.DrawScreenQuad()

	orgMat:SetTexture("$basetexture", orgText)
end

function uiskinmgr.Render_Pipeline(mat, pipeline)
	local texture = mat:GetTexture("$basetexture")
	if !pipeline || #pipeline < 1 then return texture end

	//VERY IMPORTANT to set the width and height to skin texture's w and h
	render.PushRenderTarget(rt, 0, 0, texture:Width(), texture:Height())
	cam.Start2D()
	DisableClipping(true)

	render.Clear(0,0,0,0)
	render.ClearDepth()

	surface.SetMaterial(mat)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRectUV( 0, 0, ScrW(), ScrH(), 0, 0, 1, 1)

	/*render.SetMaterial(mat)
	render.DrawScreenQuadEx(0,0, ScrW(), ScrH())*/

	for _, v in ipairs(pipeline) do
		if operations[v.operation] then
			operations[v.operation](rt, v, mat)
		end
	end

	DisableClipping(false)
	cam.End2D()
	render.PopRenderTarget()

	return rt
end