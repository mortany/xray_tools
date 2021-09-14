rollout XRayCheckInvalid_rol "check invalid faces"
(
group "" (
button WeldAllBtn "weld vertices" across:2 align:#left
spinner WeltTresh type:#float range:[0,100000,.005] width:50 align:#right scale:.001 offset:[0,2]
)
group "" (
button CheckZero "check zero area faces" width:160
)
group "" (
button CheckInv "check invalid" width:160
radiobuttons InvType labels:#("point","line") default:1 columns:2
)
group "" (
button CheckJunction "check junctions" width:160 enabled:false
)

on WeldAllBtn pressed do
	(
		clearlistener ()
	
		for obj in selection do
			if superclassof obj == GeometryClass then
			(
				if classof obj != Editable_mesh then convertToMesh obj
				N = obj.numverts
				meshop.weldVertsByThreshold obj #all WeltTresh.value
				if N == obj.numverts then format "* object % | No vertices within weld treshold\n" obj.name
				else format "* object % | verts before % , after %\n" obj.name N obj.numverts
			)
			else format "* object % is not geometry\n" obj.name
	)

on CheckZero pressed do
	(
			clearlistener ()
			
			for obj in selection where superclassof obj == GeometryClass do
			(
				if classof obj != Editable_mesh then convertToMesh obj
				fs = #{}
			
				for i = 1 to obj.numfaces do
					if (meshop.getFaceArea obj i) == 0.0 then append fs i
				
				setFaceSelection obj fs
				if fs.numberset > 0 then format "* % :zero area faces count = %\n" obj.name fs.numberset
				else format "* % : OK\n" obj.name
			)
	)

on CheckInv pressed do
	(
			clearlistener ()
			
			for obj in selection where superclassof obj == GeometryClass do
			(
				if classof obj != Editable_mesh then convertToMesh obj
				fs = #{}
			
				for i = 1 to obj.numfaces do
				(
					mf = meshop.getMapFace obj 1 i
					mv = for j = 1 to 3 collect meshop.getMapVert obj 1 mf[j]
					if InvType.state == 1 then
						is_invalid_face = (distance mv[1] mv[2] < 0.0001) and (distance mv[1] mv[3] < 0.0001)
					else
						is_invalid_face = (distance mv[1] mv[2] < 0.0001) or (distance mv[1] mv[3] < 0.0001) or (distance mv[2] mv[3] < 0.0001)
					if is_invalid_face then append fs i
				)
				
				setFaceSelection obj fs
				if fs.numberset > 0 then format "* % :invalid count = %\n" obj.name fs.numberset
				else format "* % : OK\n" obj.name
			)
	)
	
on CheckJunction pressed do
(
	clearlistener ()
	
	for obj in selection where superclassof obj == GeometryClass do
	(
		if classof obj != Editable_mesh then convertToMesh obj
		BadEdges = #{}
		
		for i = 1 to obj.numverts do
		(
			veds = (meshop.getEdgesUsingVert obj i) as array
			--format "\t|vert % edges %\n" i veds
			
			for j = 1 to veds.count-1 do
			(
				ev1 = (meshop.getVertsUsingEdge obj veds[j]) as array
				v1 = normalize ((getvert obj ev1[2])-(getvert obj ev1[1]))
				if ev1[2] == i then v1 *= -1.0
				--format "\t\t|edge % verts % vector %\n" veds[j] ev1 v1
				
				for k = j+1 to veds.count do
				(
					ev2 = (meshop.getVertsUsingEdge obj veds[k]) as array
					if ev1[1] == ev2[1] and ev1[2] == ev2[2] then continue --(format "\t\t\t|** passing edge % verts %\n" veds[k] ev2 ; continue)
					v2 = normalize ((getvert obj ev2[2])-(getvert obj ev2[1]))
					if ev2[2] == i then v2 *= -1.0
					--format "\t\t\t|edge % verts % vector %\n" veds[k] ev2 v2
					d = dot v1 v2
					if d == 1.0 then
					(
						--format "\t\t\t ############ [%,%]: % % %\n" veds[j] veds[k] v1 v2 d
						join BadEdges #{veds[j],veds[k]}
					)
				)
			)
		)
		
		if BadEdges.numberset > 0 then format "* %: junctions count = %\n" obj.name BadEdges.numberset
		else format "* %: OK\n" obj.name
		setEdgeSelection obj BadEdges
	)
)

) -- roll

try (closeRolloutFloater XRayCheckInvalid_flo) catch ()
XRayCheckInvalid_flo = newRolloutFloater "x-ray tools" 200 264 40 130
addRollout XRayCheckInvalid_rol XRayCheckInvalid_flo