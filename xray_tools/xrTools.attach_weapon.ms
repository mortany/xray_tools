-- attach weapon to finger

rollout AttachWeapon_rol "attach weapon"
(
	button attachW "attach" width:120 --tooltip:"'bip01_r_finger1'"
	pickbutton FingerObj "select finger" autoDisplay:true width:120
	label lbl_0 "scale" align:#left across:2
	spinner scale_value range:[0,100000,1] scale:.001 width:60 align:#right

	fn removeComments str = 
	(
		if (n = findstring str ";") != undefined then
		(
			if n == 1 then return ""
			else return substring str 1 (n-1)
		)
		else return str
	)

	on FingerObj rightclick do
	(
		FingerObj.object = undefined
		FingerObj.text = "select finger"
	)
	
	on attachW pressed do
	(
		if selection.count != 1 then messagebox "select just weapon object"
		else
		(
			wpn = selection[1]
			
			if not (isValidNode FingerObj.object) then messagebox "select finger object"
			else
			(
				finger = FingerObj.object
				fname = getopenfilename filename:"C:\\Program Files\\X-Ray CoP SDK\\editors\\gamedata\\configs\\weapons\\*.ltx"
				
				if fname != undefined then
				(
					clearlistener()
					
					sect = getinisetting fname
					str = removeComments ( getinisetting fname sect[1] "position" )
					p = execute ("[" + str + "]")
					pos = [p.z, -p.x, p.y]*scale_value.value
					str = removeComments ( getinisetting fname sect[1] "orientation" )
					rot = execute ("[" + str + "]")
					
					format "position = %\norientation = %\n" pos rot
					
					tm = rotateZMatrix (-90)
					tm = (rotateZMatrix -rot.x)*tm
					tm = (rotateYMatrix -rot.z)*tm
					tm = (rotateXMatrix rot.y)*tm
					tm *= transmatrix pos
					tm *= finger.transform
					
					wpn.transform = tm
					wpn.parent = finger
				)
			)
		)
	)
)

try (closeRolloutFloater AttachWeapon_flo) catch ()
AttachWeapon_flo = newRolloutFloater "x-ray tools" 150 110 40 330
addRollout  AttachWeapon_rol AttachWeapon_flo