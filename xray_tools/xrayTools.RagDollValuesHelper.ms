rollout RagDollHelper_rol ""
(

button doit "evaluate ragdoll angles"

fn getMaxMinValue c sc =
(
	local res = undefined, k, v, z = 0
	for k in sc.keys do
	(
		v = -(at time k.time c.value) as integer
		if res == undefined then (res = #(v,v); z = v; continue)
		if v<res[1] then res[1] = v
		if v>res[2] then res[2] = v
	)
	if res != undefined then return [res[1] - z, res[2] - z]
	else undefined
)


on doit pressed do
(
	clearlistener()

	max create mode
	with redraw off 
	for obj in selection do
	(
		if classof obj.rotation.controller != Euler_XYZ then format "%: rotation controller not Euler_XYZ\n" obj.name
		else
		(
			sc = obj.rotation.controller
			if sc.keys.count == 0 then continue
			i = getTimeRange sc #children
			if i.start < -100 or i.end > 9999 then (format "hm... cant evaluate %" obj.name; continue)
			
			bob = dummy()
			--tm = inverse (at time i.start obj.transform)
			ptm = if obj.parent == undefined then matrix3 1 else at time i.start (inverse obj.parent.transform)
			tm = inverse (at time i.start obj.transform*ptm)
			
			for t = i.start to i.end do
			(
				ptm = if obj.parent == undefined then matrix3 1 else at time t (inverse obj.parent.transform)
				animate on at time t bob.transform = (obj.transform * ptm) * tm
			)
					
			format "%\n" obj.name
			format "\tX  %\n" (getMaxMinValue bob.rotation.x_rotation.controller obj.rotation.x_rotation.controller) 
			format "\tY  %\n" (getMaxMinValue bob.rotation.z_rotation.controller obj.rotation.z_rotation.controller)
			format "\tZ  %\n" (getMaxMinValue bob.rotation.y_rotation.controller obj.rotation.y_rotation.controller)
		)
		delete bob
	)
)

) -- roll

try (closeRolloutFloater RagDollHelper_flo) catch ()
RagDollHelper_flo = newRolloutFloater "" 160 70 200 200
addRollout RagDollHelper_rol RagDollHelper_flo