rollout RunningMob_rol "running mob"
(
	button Doit "set mob on path"
	label Label_01 "speed" across:2 align:#left
	spinner spd type:#float range:[0,100000,5] width:60 align:#right
	
	fn box_filt obj = classof obj == line or classof obj == SplineShape
	
	pickbutton chooseit "Select spline" width:140 filter:box_filt autoDisplay:true

	fn SetupBones obj =
	(
		local c = obj.transform.controller, i
		setBeforeORT c #cycle
		setAfterORT c #cycle
		--obj.name = Prefix + obj.name
		for i in obj.children do SetupBones i
	)

	on Doit pressed do
		if chooseit.object != undefined and isvalidNode chooseit.object and selection.count == 1 then
		(
			obj = selection[1]
			SetupBones obj

			Root = dummy boxsize:[1,1,1]
			obj.parent = Root

			Spl = chooseit.object
			Ls = getSegLengths spl 1
			L = Ls[Ls.count]

			t= (30*L/spd.value) as integer
			C = Path_Constraint path:Spl follow:true axis:1
			deletekeys c #allKeys
			
			Root.position.controller = C
			animate on at time t C.percent = 100
			setBeforeORT c #relativeRepeat
			setAfterORT c #relativeRepeat
		)
)

try (closeRolloutFloater RunningMob_flo) catch ()
RunningMob_flo = newRolloutFloater "" 160 120 40 130
addRollout RunningMob_rol RunningMob_flo