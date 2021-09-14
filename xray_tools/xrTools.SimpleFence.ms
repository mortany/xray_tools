-- wooden fence v3

rollout BarwireFence_rol "simple fence params"
(
button buildit "Create" align:#left across:2 width:80
button DelLast "Delete last" align:#right width:80

label L001 "Height" align:#left across:3
spinner SHeight range:[0,999999,2] width:50 align:#right
--label L004 "Post Height (max)" align:#left across:2
spinner SHeightPM range:[0,999999,2.2] width:50 align:#right
label L002 "Tilt" align:#left across:3
spinner STilt range:[-180,180,-5] width:50 align:#right
spinner STiltMax range:[-180,180,5] width:50 align:#right
label L003 "Radius" align:#left across:2
spinner SRadius range:[0,999999,.1] width:50 align:#right scale:.01
label L005 "Post num sides" align:#left across:2
spinner SNumSides type:#integer range:[3,9999,8] width:50 align:#right
label L013 "Post X offset" align:#left across:3
button GetXOfs " " width:20 height:16 align:#right
spinner XOffsetAll range:[-9999990,999999,0] width:50 align:#right scale:.01
label L014 "Post Z rotation" align:#left across:2
spinner PostZRotation range:[-9999990,999999,0] width:50 align:#right
label L011 "Z offset" align:#left across:2
spinner ZOffsetAll range:[-9999990,999999,-.1] width:50 align:#right

--checkbox RotatePost "rotate post"
checkbox endCone "top as cone" align:#left across:2
spinner endConeH range:[0,999999,.1] width:50 align:#right scale:.01
checkbox delbot "Post delete bottom" checked:true
checkbox deltop "Post delete top"


label L007 "wires start offset" align:#left across:2
spinner WStart range:[0,999999,.2] width:50 align:#right
label L008 "wires end offset" align:#left across:2
spinner WEnd range:[0,999999,.1] width:50 align:#right

group "materials"
(
materialbutton PostMaterial "select post material" width:160
materialbutton FenceMaterial "select wire material" width:160
)

group "custom post object"
(
pickbutton PostObject "none" message:"select custom post object" autoDisplay:true width:160
)

group ""
(
button PutSplineOnMeshes "Drop spline to meshes"
)

local objpost = undefined
local objfence = undefined

on GetXOfs pressed do
(
	alpha = 360./SNumSides.value
	beta = mod PostZRotation.value alpha
	x = SRadius.value / (1 + tan(beta)*tan(alpha/2))
	y = x * tan(beta)
	XOffsetAll.value = length [x,y,0]
)

on SHeight changed arg do
	if arg > SHeightPM.value then SHeightPM.value = arg
	
on SHeightPM changed arg do
	if arg < SHeight.value then SHeight.value = arg

on PostMaterial picked mat do PostMaterial.text = "post mat : " + mat.name

on PostMaterial rightclick do
(
	PostMaterial.material = undefined
	PostMaterial.text = "select post material"
)
on FenceMaterial picked mat do FenceMaterial.text = "wire mat : " + mat.name

on FenceMaterial rightclick do
(
	FenceMaterial.material = undefined
	FenceMaterial.text = "select wire material"
)

on PostObject picked ooo do
(
	--L001.enabled = false
	--SHeight.enabled = false
	--L004.enabled = false
	SHeightPM.enabled = false
	--L002.enabled = false
	--STilt.enabled = false
	L003.enabled = false
	SRadius.enabled = false
	L005.enabled = false
	SNumSides.enabled = false
	--L011.enabled = false
	--ZOffsetAll.enabled = false
	--RotatePost.enabled = false
	endCone.enabled = false
	endConeH.enabled = false
	delbot.enabled = false
	deltop.enabled = false
)

on PostObject rightclick do
(
	PostObject.object = undefined
	PostObject.text = "none"
	--L001.enabled = true
	--SHeight.enabled = true
	--L004.enabled = true
	SHeightPM.enabled = true
	--L002.enabled = true
	--STilt.enabled = true
	L003.enabled = true
	SRadius.enabled = true
	L005.enabled = true
	SNumSides.enabled = true
	--L011.enabled = true
	--ZOffsetAll.enabled = true
	--RotatePost.enabled = true
	endCone.enabled = true
	endConeH.enabled = true
	delbot.enabled = true
	deltop.enabled = true
)

on PutSplineOnMeshes pressed do
(
		for spl in selection where (classof spl == line) or (classof spl == SplineShape) do
		(
				for i = 1 to numSplines spl do
					for j = 1 to numKnots spl i do
					(
						ClickRay = ray (getknotpoint spl i j) [0,0,-1]
						dist = 999999.
						PosRay = undefined
						
						for obj in $geometry where not obj.isHidden do
							if (IntRay = intersectRay obj ClickRay) != undefined then
								if (d = distance IntRay.pos ClickRay.pos) < dist then (dist = d; PosRay = IntRay)
						
						if PosRay != undefined then setknotpoint spl i j PosRay.pos
					)
				updateshape spl
		)
)

on DelLast pressed do
(
		if objpost != undefined then
			if not isDeleted objpost then delete objpost
		--if objfence != undefined then
			--if not isDeleted objfence then delete objfence
)


on buildit pressed do
	if $ != undefined then
	(
		obj = selection[1]
		UseCustom = IsValidNode PostObject.object
			
		if classof obj == line or classof obj == SplineShape then
		(	
			fob = undefined
			sob = undefined
			SetkaMat = if FenceMaterial.material == undefined then standard () else FenceMaterial.material
			PostMat = if PostMaterial.material == undefined then standard () else PostMaterial.material
		
			max create mode

			with redraw off
				for i = 1 to NumSplines obj do
				(
					NumK = numknots obj i
					Pts = #()
					
					for j = 1 to NumK do
					(
						p1 = getknotpoint obj i j
						p0 = if j > 1 then getknotpoint obj i (j-1) else if isClosed obj i then getknotpoint obj i NumK else getknotpoint obj i j
						p2 = if j < NumK then getknotpoint obj i (j+1) else if isClosed obj i then getknotpoint obj i 1 else getknotpoint obj i j
						vy = normalize (p2 - p1 + p1 - p0)
						vz = [0,0,1]
						vx = cross vy vz
						vy = cross vz vx
						tm = matrix3 vx vy vz p1
						
						if UseCustom then
						(
							b = copy PostObject.object
							convertTo b editable_poly
							b.transform = (RotateZMatrix PostZRotation.value)
							b.pos = [XOffsetAll.value,0,0]
						)
						else
						(
							b = cylinder 	radius:SRadius.value height:((random SHeight.value SHeightPM.value)) \
											sides:SNumSides.value Cap_Segments:1 Height_Segments:1 smooth:true slice:false mapCoords:true 
							b.transform = (RotateZMatrix PostZRotation.value)
							b.pos = [XOffsetAll.value,0,0]
							convertTo b editable_poly
							mf = polyop.getnummapverts b 1
							for k = (mf - SNumSides.value*2 + 1) to mf do
								polyop.setmapvert b 1 k ((polyop.getmapvert b 1 k) + [0,2,0])
							polyop.setfacematid b #all 1
							delfa = #{}
							if delbot.checked then delfa[SNumSides.value+1] = true
							if deltop.checked then delfa[SNumSides.value+2] = true
							else
								if endCone.checked then
								(
									b.tesselateBy = 1
									polyop.setfaceselection b (SNumSides.value+2)
									b.tessellate #face
									polyop.setvert b b.numverts ((polyop.getvert b b.numverts) + [0,0,1]*endConeH.value)
								)
							polyOp.deleteFaces b delfa delIsoVerts:true
						)
						
						Pts[j] = #(#())
						Pts[j][1] = [0,0,WStart.value]
						Pts[j][2] = Pts[j][1] + [0,0,SHeight.value - WEnd.value - WStart.value]
						
						
						tm = (RotateYMatrix (random STilt.value STiltMax.value))*tm
						b.transform *= tm
						for k = 1 to 2 do Pts[j][k] *= tm
						
						if fob == undefined then fob = b else polyOp.attach fob b
					)
					
					for j = 1 to NumK do
					(
						k = j + 1
						if j == NumK then if isClosed obj i then k = 1 else exit
						b = plane Length_Segments:1 Width_Segments:1
						convertTo b editable_poly
						polyop.setfacematid b 1 2
						polyop.setvert b 1 Pts[j][1]
						polyop.setvert b 3 Pts[j][2]
						polyop.setvert b 2 Pts[k][1]
						polyop.setvert b 4 Pts[k][2]
						L = length (Pts[k][2] - Pts[j][1])
						L /= (SHeight.value - WEnd.value - WStart.value)
						polyop.setmapvert b 1 2 [L,0,0]
						polyop.setmapvert b 1 4 [L,1,0]
						if sob == undefined then sob = b else polyOp.attach sob b
					)
				)
			
			sob.material = SetkaMat
			if not UseCustom then fob.material = PostMat
			
			sob.weldThreshold = 0.002
			polyOp.weldVertsByThreshold sob #all
			polyOp.attach fob sob
			--fob.material = multimaterial numsubs:2
			objpost = fob
			objpost.pos.z += ZOffsetAll.value
			objpost.pivot = [0,0,0]
			resetxform objpost
			convertTo objpost editable_poly
			objpost.name = uniqueName "simple_fence_"
		) -- is shape
	)


) -- roll

try (closerolloutfloater BarwireFence_flo) catch ()
BarwireFence_flo = newrolloutfloater "simple fence" 210 520 200 200
addrollout BarwireFence_rol BarwireFence_flo