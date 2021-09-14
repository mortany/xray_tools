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
	
	fn GetProp obj prop val =
	(
		local p = getuserprop obj prop
		if p == undefined then return val
		return p
	)
	
) -- stru