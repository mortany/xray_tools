global xrToolsUtil

struct xrToolsUtil
(
	fn renameBone str = 		-----------------------------------------------------------------------------
	( 
		if str == undefined then return ""
		local upper, lower, outstring
		upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ "
		lower = "abcdefghijklmnopqrstuvwxyz_"
		outstring = copy str
		for i = 1 to outstring.count do
		( 
			j = findString upper outstring[i]
			if (j != undefined) do outstring[i] = lower[j]
		)
		return outstring 
	),


	
	fn HasShadersCA Mtl = 		-----------------------------------------------------------------------------
	(
		if Mtl != undefined then
		(
			local i, ca
			
			for i = 1 to (custAttributes.count Mtl) do
			(
				ca = custAttributes.get Mtl i
				if ca.name == "xrShadersData" then return true
			)
		)
		return false
	),

	fn CheckIgnoreShaders mtl1 mtl2 ignr_2s ignr_shrs ignr_cshrs ignr_mtl =		-----------------------------------------------------------------------------
	(
		if (not ignr_2s and mtl1.twoSided != mtl2.twoSided) then
			return false

		local ShaderName1 = "default"
		local CShaderName1 = "default"
		local MtlName1 = "default"
		if xrToolsUtil.HasShadersCA mtl1 then
		(
			ShaderName1 = mtl1.EShader
			CShaderName1 = mtl1.CShader
			MtlName1 = mtl1.GameMaterial
		)

		local ShaderName2 = "default"
		local CShaderName2 = "default"
		local MtlName2 = "default"
		if xrToolsUtil.HasShadersCA mtl2 then
		(
			ShaderName2 = mtl2.EShader
			CShaderName2 = mtl2.CShader
			MtlName2 = mtl2.GameMaterial
		)

		if (not ignr_shrs and stricmp ShaderName1 ShaderName2 != 0) then
			return false

		if (not ignr_cshrs and stricmp CShaderName1 CShaderName2 != 0) then
			return false

		if (not ignr_mtl and stricmp MtlName1 MtlName2 != 0) then
			return false

		return true
	),
	
	fn GetProp obj prop val =
	(
		local p = getuserprop obj prop
		if p == undefined then return val
		return p
	)
	
) -- stru