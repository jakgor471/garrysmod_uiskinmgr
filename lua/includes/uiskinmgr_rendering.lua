uiskinmgr = uiskinmgr or {}

local mat_Downsample = Material( "pp/downsample" )
local mat = CreateMaterial("uiskinmgr_helpermaterial", "UnlitGeneric", {
	["$basetexture"] = "vgui/white",
	["$translucent"] = 1,
	["$vertexcolor"] = 1
})

local rt = GetRenderTargetEx("uiskinmgr_rendertarget4", 512, 512, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(1, 256), 0, IMAGE_FORMAT_BGRA8888)

function uiskinmgr.Render_Tint(texture, color, intensity)
	if !texture then return end

	mat:SetTexture("$basetexture", texture)

	//VERY IMPORTANT to set the width and height to skin texture's w and h
	render.PushRenderTarget(rt, 0, 0, texture:Width(), texture:Height())
	cam.Start2D()

	render.Clear(0,0,0,0)
	render.ClearDepth()

	//render.SetMaterial(mat)
	//render.DrawScreenQuadEx(0,0, ScrW(), ScrH()) seems no to be working, the texture gets squished
	//render.DrawScreenQuad()
	surface.SetMaterial(mat)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

	/*render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_DST_COLOR, BLENDFUNC_ADD, BLEND_DST_ALPHA, BLEND_SRC_ALPHA, BLENDFUNC_MIN)
	surface.SetDrawColor( color )
	surface.DrawRect(0, 0, ScrW(), ScrH())
	render.OverrideBlend(false)*/

	cam.End2D()
	render.PopRenderTarget()

	return rt
end