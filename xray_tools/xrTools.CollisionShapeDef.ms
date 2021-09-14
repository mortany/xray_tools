plugin simpleObject XRayCollision
name:"XRayCollision"
classID:#(63499,55532)
category:"Scripted Primitives"
( 
	local obj, i
	local boxva = #( \
		#([-1,-1,-1],[1,-1,-1],[-1,1,-1],[1,1,-1],[-1,-1,1],[1,-1,1],[-1,1,1],[1,1,1]), \
		#([0,0,-0.5],[1,0,-0.5],[0.707107,0.707107,-0.5],[0,1,-0.5],[-0.707107,0.707107,-0.5],[-1,0,-0.5], \
			[-0.707107,-0.707107,-0.5],[0,-1,-0.5],[0.707107,-0.707107,-0.5],[1,0,0.5],[0.707107,0.707107,0.5],[0,1,0.5], \
			[-0.707107,0.707107,0.5],[-1,0,0.5],[-0.707107,-0.707107,0.5],[0,-1,0.5],[0.707107,-0.707107,0.5],[0,0,0.5]) \
		)
	local boxfa = #( \
		#([1,3,4],[4,2,1],[5,6,8],[8,7,5],[1,2,6],[6,5,1],[2,4,8],[8,6,2],[4,3,7],[7,8,4],[3,1,5],[5,7,3]), \
		#([1,3,2],[1,4,3],[1,5,4],[1,6,5],[1,7,6],[1,8,7],[1,9,8],[1,2,9],[2,11,10],[2,3,11],[3,12,11],[3,4,12],[4,13,12], \
			[4,5,13],[5,14,13],[5,6,14],[6,15,14],[6,7,15],[7,16,15],[7,8,16],[8,17,16], \
			[8,9,17],[9,10,17],[9,2,10],[18,10,11],[18,11,12],[18,12,13],[18,13,14],[18,14,15],[18,15,16],[18,16,17],[18,17,10]) \
		)
	
	parameters main rollout:params
	(
	stype type:#radiobtnIndex ui:stype default:1
	length type:#worldUnits ui:length default:1E-3
	width type:#worldUnits ui:width default:1E-3
	height type:#worldUnits ui:height default:1E-3
	sradius type:#worldUnits ui:sradius default:1E-1
	cradius type:#worldUnits ui:cradius default:1E-1
	cheight type:#worldUnits ui:cheight default:1
	mass type:#worldUnits ui:mass default:10
	)
	
	rollout params "X-Ray Collision"
	(
		radiobuttons stype "type" labels:#("box","sph","cyl") columns:3
		group "box"
		(
			spinner height "Height" type:#worldUnits range:[1E-3,1E9,1E-3] scale:0.01
			spinner width "Width" type:#worldUnits range:[1E-3,1E9,1E-3] scale:0.01
			spinner length "Length" type:#worldUnits range:[-1E9,1E9,1E-3] scale:0.01
		)
		group "sphere"
		(
			spinner sradius "Radius" type:#worldUnits range:[1E-3,1E9,1E-3] scale:0.01
		)
		group "cylinder"
		(
			spinner cradius "Radius" type:#worldUnits range:[1E-3,1E9,1E-3] scale:0.01
			spinner cheight "Height" type:#worldUnits range:[1E-3,1E9,1E-3] scale:0.01
		)
		group "params"
		(
			spinner mass "Mass" type:#worldUnits range:[1E-3,1E9,10]
			
		)
	)
	
	on buildMesh do
	(
		
		case stype of
		(
			1:
			(
				obj = undefined
				setmesh mesh verts:(for i in boxva[1] collect (i*[width,length,height])) faces:boxfa[1]
				for i = 1 to mesh.numfaces do setFaceSmoothGroup mesh i 0
			)
			2:
			(
				if obj == undefined then (obj = createInstance sphere; obj.segments = 16)
				obj.radius = sradius
				obj.mapCoords = false
				setMesh mesh obj.mesh
			)
			3:
			(
				obj = undefined
				setmesh mesh verts:(for i in boxva[2] collect (i*[cradius,cradius,cheight])) faces:boxfa[2]
				for i = 1 to mesh.numfaces do setFaceSmoothGroup mesh i (if i > 8 and i < 25 then 1 else 2)
			)
		)
	)
	
	tool create
	(
		on mousePoint click do
			case click of
			(
				1: nodeTM.translation = gridPoint
				3: #stop
			)
		
		on mouseMove click do
			case click of
			(
				2: (width = abs gridDist.x; length = abs gridDist.y; sradius = abs gridDist.y; cradius = abs gridDist.y)
				3: (height = gridDist.z; cheight = gridDist.z)
			)
	) -- tool create

) -- plug
