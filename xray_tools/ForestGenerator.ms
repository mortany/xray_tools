rollout progressTest "Progress"
(
	label GroupID "creating group 1"
	progressbar prog color:red
)

rollout ExportSceneStatic_rol "export objects"
(
	button ExportStatic "Export selected" width:180

	fn IntToString A n =
	(
		local i , str = A as string
		local m = n - str.count
		for i = 1 to m do str = "0" + str
		str
	)

	fn ReadIni_Int fname section_string key_string = 
	(
		local s = getINISetting fname section_string key_string
		if s == "" then return undefined
		execute (s)
	)

	fn Export_ipl fname start_index check_names =
	(
			local objects_count = ReadIni_Int fname "main" "objects_count"
			if objects_count == undefined then return #("Bug report:","objects_count = undefined")
			
			local Report = #("Bug report:")
			local names = #(), names_index = #()
			createDialog progressTest 200 80
			
			if check_names then
			(
					progressTest.groupid.text = "stage 1: collecting indexes"
					progressTest.prog.value = 0
				
					for i = 1 to objects_count do
					(
							progressTest.prog.value = 100.*i/objects_count
						
							section_string = "object_" + ((i-1) as string)
							iname = getINISetting fname section_string "name"
							ref_name = getINISetting fname section_string "reference_name"
							
							if (matchpattern iname pattern:(ref_name + "*") ignorecase:true) then
							(
									aname = substring iname (ref_name.count + 1) -1
									cnum = ""
									
									for j = aname.count to 1 by -1 do
											if (findstring aname[j] "0123456789") == undefined then
											(
													cnum = substring aname (j+1) -1
											)
									
									if cnum == "" then cnum = 0 else cnum = try (execute cnum) catch (undefined)
									
									inList = false
									
									for j = 1 to names.count do
											if ( stricmp names[j] ref_name ) == 0 then
											(
													inList = true
													if cnum == undefined then names_index[j] += 1
													else
															if names_index[j] < cnum then names_index[j] = cnum
													exit
											)
									
									if not inList then (append names ref_name ; append names_index start_index)
							)
							--else append Report ("warning: name not patterned to ref name (" + iname + ":" + ref_name + ")")
					)
			
			)
			format "\n\n"

			SDKObjectsPath = getIniSetting (scriptspath + "xr_scripts_settings.txt") "paths" "last_objects_path"
			progressTest.groupid.text = "stage 2: writing"
			progressTest.prog.value = 0
			
			--------------------------------------------------------------------------------------------------------------- export
			PInd = 1 ; PindMax = selection.count
			
			for obj in selection where obj.parent == undefined do
			(
					progressTest.prog.value = 100.*Pind/PindMax ; PInd += 1
				
					ref_name = getuserprop obj "ref_name"
					if ref_name == undefined then ref_name = getuserprop obj "RefObj"
					
					
					if ref_name == undefined then ( append Report ("no \"ref_name\" property [" + obj.name + "]") )
					else
					(
							if not doesFileExist (SDKObjectsPath + "\\" + ref_name + ".object") then 
									append Report ("file not exist \"" + ref_name + ".object\"")
							
							objects_count += 1
							suf = ""
							
							for i = 1 to names.count do
									if ( stricmp names[i] ref_name ) == 0 then
									(
											--if names_index[i] == undefined then names_index[i] = start_index + 1
											--else 
											names_index[i] += 1
											suf = "_" + IntToString names_index[i] 5
											exit
									)
							
							if suf == "" then 
							(
									suf = "_" + IntToString start_index 5
									append names ref_name
									append names_index start_index
							)
							
							--format ":%\n" (ref_name + suf)
							
							rot = quattoeuler obj.transform.rotation order:4
							--rot = quattoeuler (obj.transform.rotationpart) order:4
							rx = degtorad (rot.x)
							ry = degtorad (rot.y)
							rz = degtorad (rot.z)
							
							format "[object_%]\n" (objects_count - 1)
							format "\tclsid\t\t\t\t= 2\n"
							format "\tco_flags\t\t\t= 0\n"
							format "\tflags\t\t\t\t= 0\n"
							format "\tname\t\t\t\t= %\n" (ref_name + suf)
							format "\tposition\t\t\t= %, %, %\n" obj.position.x obj.position.z obj.position.y
							format "\treference_name\t\t\t= %\n" ref_name
							format "\trotation\t\t\t= %, %, %\n" ry rz rx --rx rz ry
							format "\tscale\t\t\t\t= %, %, %\n" obj.scale.x obj.scale.z obj.scale.y
							format "\tversion\t\t\t\t= 18\n\n"
							
							
					)
			)
			
			format "\nobjects_count = %\n" objects_count
			destroyDialog progressTest
			return Report
	)

	on ExportStatic pressed do
	(
		fname = getopenfilename filename:"scene_object.part" types:"x-ray sdk level part|*.part|"

		if fname != undefined then
		(
				clearlistener ()
				emsg = Export_ipl fname 0 true
				for str in emsg do format "|%\n" str
		)
	)
)

rollout renderLod_rol "render lod"
(

button render_it "RENDER" across:2 align:#left width:180
spinner numplanes "num planes" type:#integer range:[0,100000,3] width:80 align:#right offset:[0,3]
label Label_01 "render texture path" align:#left
edittext TexturaPath text:"D:\\MAX_SCENES\\STALKER\\textures_lod\\" across:2 align:#left width:260 height:20
button getOutDir "get" align:#right
checkbox UseExist "use existing texture" chwecked:false

local textureDir = "D:\\MAX_SCENES\\STALKER\\textures_lod\\"

fn filterName str =
(
	local res = "", i
	for i = 1 to str.count do 
		if (findstring "!@#$%^&*" str[i]) == undefined then res[i] = str[i]
	return res
)

fn CreatePlane obj a =
(
	local g = obj.max - obj.min, c = [obj.pos.x , obj.pos.y, obj.center.z]
	local m = (rotatezmatrix a)*(transmatrix c), im = inverse m
	local p = #()
	p[1] = ([obj.min.x, obj.min.y, c.z]*im).x
	p[2] = ([obj.min.x, obj.max.y, c.z]*im).x
	p[3] = ([obj.max.x, obj.min.y, c.z]*im).x
	p[4] = ([obj.max.x, obj.max.y, c.z]*im).x
	local w = (amax p) - (amin p)
	local po = plane length:g.z width:w lengthsegs:1 widthsegs:1 mapCoords:true renderScale:1 density:1
	po.rotation.x_rotation = 90
	po.transform *= m
	
	--format "%, %\n" a p
	return po
)

fn RenderFromPlane obj s fname =
(
	local z = (amax obj.width obj.length)/2
	local m = (transmatrix [0,0,z])*obj.transform
	local cam = freecamera fov:90 orthoProjection:true targetDistance:z
	cam.transform = m
	render camera:cam outputSize:s outputfile:fname quiet:true vfb:false
	delete cam
)

on getOutDir pressed do
(
	str = getsavepath initialdir:TexturaPath.text
	if str != undefined then (
		TexturaPath.text = str + "\\"
		textureDir = str + "\\"
	)
)

on render_it pressed do
(
		textureDir = TexturaPath.text
		NotRederable = #()
		for obj in $geometry do  if not obj.renderable then append NotRederable obj
		
		for sob in selection do
		(
			me = undefined
			Np = numplanes.value
			Mult = 180./Np
			
			for obj in $geometry where obj!=sob do obj.renderable = false
			
			for i = 0 to Np-1 do 
			(
				po = CreatePlane sob (i*Mult)
				setRenderable po false
				fname = textureDir + (sob.name) + "_lod" + (i as string) + ".tga"
				if (doesfileexist fname) and UseExist.checked then
				(
					--
				)
				else
				(
					RenderFromPlane po [128,128] fname
				)
				
				mat = standard twoSided:true
				mat.diffusemap = bitmaptexture filename:fname monoOutput:0 RGBOutput:0 alphasource:2
				mat.opacitymap = bitmaptexture filename:fname monoOutput:1 RGBOutput:1 alphasource:0
				showTextureMap mat true
				po.material = mat
				L = amax po.width po.length
				mod = uvwmap length:L width:L
				addmodifier po mod
				converttomesh po
				if me == undefined then me = po else attach me po
			)
			
			for obj in $geometry where obj!=sob do obj.renderable = true
			
			setuserpropbuffer me (getUserPropBuffer sob)
			me.name = "LOD_" + sob.name
			me.pivot = sob.pivot
			resetXForm me
			converttomesh me
		)
)

)

rollout XRayCloner_rol ""
(
	fn TFilter obj = classof obj == Editable_mesh or classof obj == Editable_poly
	pickbutton TerrainPick "Get Terrain Object First" filter:TFilter autoDisplay:true width:320 height:30
	
	button Create "Build" across:2 align:#left width:200 height:30
	button DeleteLast "Delete Last" align:#right width:110 height:30
	label L05 "Number Of Test Points" across:3 align:#left
	spinner TestPointsNum type:#integer range:[10,999999,10000] width:60 align:#left
	checkbox UseSub "Use Subobject" align:#right
	label LastCount ""
	
	group ""
	(
		label L01 "Group ID" across:4 align:#left
		spinner SprGroupID type:#integer range:[1,1,1] width:40 align:#left
		button AddGroupBtn "Add Group" align:#left offset:[-10,0]
		button DelGroupBtn "Delete last Group" align:#right
		
		Label L03 "Min Distance To Group" align:#left across:3
		spinner MinDistID type:#integer range:[1,1,1] width:40 align:#left
		spinner SprMinDist ">" range:[0,99999999,10] width:70 align:#right
	)
	group ""
	(
		listbox InGroupObjectsList "Group Objects" items:#() height:10
		button AddObjectInGroupBtn "Get Objects" across:2 align:#left width:150
		button AssociateSelected "Associate selected" align:#right width:150
		
		checkbox AlignNormalChk "Aling Normals" across:3 align:#left
		checkbox RandomRotChk "Random Z Rotation" checked:true
		spinner SprZOffset "Z Offset" range:[-9999999,9999999,0] width:90 align:#right
		Label L08 "Scale Object" align:#left across:3
		spinner ScaleMin "Min" range:[0,99999999,1] width:70 align:#right
		spinner ScaleMax "Max" range:[0,99999999,1] width:70 align:#right
		checkbox ChageToAll "change all in group" checked:true
	)
	
	group ""
	(
		button MouseCreate "Create objects by click" width:240
		radiobuttons MouseUseSelected labels:#("group random","group selected","scene selected") columns:3
	)
	
	struct ObjectStruct (
		RefName = "",
		RefObject = undefined,
		AlignNormals = false,
		RandomRotation = true,
		ZOffset = 0.0,
		Scale = [1,1]
	)
	struct GroupStruct (
		Obj = #(),
		MinDist = #()
	)
	
	local GroupList = #(GroupStruct MinDist:#(10.)), CreatedObjectList = #(), GroupCnt = 1
	
	fn RefreshObjectParams g i =
	(
		if GroupList[g].obj.count == 0 then return undefined
		AlignNormalChk.checked = GroupList[g].obj[i].AlignNormals
		RandomRotChk.checked = GroupList[g].obj[i].RandomRotation
		SprZOffset.value = GroupList[g].obj[i].ZOffset
		ScaleMin.value = GroupList[g].obj[i].Scale[1]
		ScaleMax.value = GroupList[g].obj[i].Scale[2]
	)
	
	fn RefreshGroupList i =
	(
		tempArray = for j in GroupList[i].obj where isValidNode j.refObject collect (j.refObject.name + " | " + j.RefName)
		InGroupObjectsList.items = tempArray
		InGroupObjectsList.selection = 1
		RefreshObjectParams i 1
		SprMinDist.value = GroupList[i].MinDist[1]
	)
	
	fn xor b1 b2 = (not (b1 and b2)) and (b1 or b2)
	
	on SprMinDist changed i do GroupList[SprGroupID.value].MinDist[MinDistID.value] = i
	on MinDistID changed i do SprMinDist.value = GroupList[SprGroupID.value].MinDist[i]
		
	on ScaleMin changed i do 
		if GroupList[SprGroupID.value].obj.count > 0 then 
			for k = (if ChageToAll.checked then 1 else InGroupObjectsList.selection) to (if ChageToAll.checked then GroupList[SprGroupID.value].obj.count else InGroupObjectsList.selection) do
				GroupList[SprGroupID.value].obj[k].Scale[1] = i
	on ScaleMax changed i do 
		if GroupList[SprGroupID.value].obj.count > 0 then 
			for k = (if ChageToAll.checked then 1 else InGroupObjectsList.selection) to (if ChageToAll.checked then GroupList[SprGroupID.value].obj.count else InGroupObjectsList.selection) do
				GroupList[SprGroupID.value].obj[k].Scale[2] = i
	on AlignNormalChk changed i do
		if GroupList[SprGroupID.value].obj.count > 0 then
			for k = (if ChageToAll.checked then 1 else InGroupObjectsList.selection) to (if ChageToAll.checked then GroupList[SprGroupID.value].obj.count else InGroupObjectsList.selection) do
				GroupList[SprGroupID.value].obj[k].AlignNormals = i
	on RandomRotChk changed i do 
		if GroupList[SprGroupID.value].obj.count > 0 then
			for k = (if ChageToAll.checked then 1 else InGroupObjectsList.selection) to (if ChageToAll.checked then GroupList[SprGroupID.value].obj.count else InGroupObjectsList.selection) do
				GroupList[SprGroupID.value].obj[k].RandomRotation = i
	on SprZOffset changed i do 
		if GroupList[SprGroupID.value].obj.count > 0 then
			for k = (if ChageToAll.checked then 1 else InGroupObjectsList.selection) to (if ChageToAll.checked then GroupList[SprGroupID.value].obj.count else InGroupObjectsList.selection) do
				GroupList[SprGroupID.value].obj[k].ZOffset = i
	
	on AssociateSelected pressed do
		if GroupList[SprGroupID.value].Obj.count > 0 then
		(
			fpath = getsavepath caption:"get objects path"
			if fpath != undefined then
			(
				fname = getopenfilename types:"XRay object|*.object|" filename:(fpath + "\\")
				if fname != undefined then
				(
					str = substring fname (fpath.count+2) -1
					str = substring str 1 (str.count-7)
					format "we=%\n" str
					GroupList[SprGroupID.value].obj[InGroupObjectsList.selection].RefName = str
					RefreshGroupList SprGroupID.value
				)
			)
		)
	on AddGroupBtn pressed do
	(
		GroupCnt += 1
		SprGroupID.range = [1,GroupCnt,GroupCnt]
		i = GroupStruct MinDist:(for k = 1 to GroupCnt collect 10.) obj:#()
		GroupList[GroupCnt] = i
		SprGroupID.value = GroupCnt
		MinDistID.range = [1,GroupCnt,1]
		RefreshGroupList GroupCnt
	)
	
	on DelGroupBtn pressed do 
		if GroupCnt > 1 then
		(
			GroupList[GroupCnt] = undefined
			GroupCnt -= 1
			SprGroupID.range = [1,GroupCnt,GroupCnt]
			SprGroupID.value = GroupCnt
			MinDistID.range = [1,GroupCnt,1]
			RefreshGroupList GroupCnt
		)
	
	on AddObjectInGroupBtn pressed do if selection.count>0 then
	(
		GroupList[SprGroupID.value].Obj = #()
		
		for obj in selection do
		(
			i = getuserprop obj "ref_name"
			if i == undefined then i = "not associated"
			append GroupList[SprGroupID.value].Obj (ObjectStruct RefObject:obj RefName:i)
		)

		RefreshGroupList SprGroupID.value
	)
	
	on SprGroupID changed v do
	(
		MinDistID.range = [1,v,1]
		RefreshGroupList v
	)
	
	on InGroupObjectsList selected i do
	(
		RefreshObjectParams SprGroupID.value i
	)
	
	fn GenerateObjects =
	(
		if not isValidNode TerrainPick.object then (messagebox "select terrain object"; return undefined)
		createDialog progressTest 200 80
		StartTime = timestamp()
		CreatedObjectList = #()
		CreatedObjectList = for i = 1 to GroupCnt collect #()
		UsedPoints = #{}
		CreatedCnt = 0
		
		PA = parray name:"temp_PArray_zx9999" \
				emitter:TerrainPick.object formation:3 numDistinctPoints:TestPointsNum.value \
				Use_Selected_Subobjects:UseSub.TriState quantityMethod:1 \
				total_number:TestPointsNum.value iconHidden:true \
				speed:0.0 Speed_Variation:0  Emitter_Start:(sliderTime-10) Emitter_Stop:(sliderTime-10) life:30 \
				isHidden:false viewPercent:100 \
				seed:(random 0 1000)
		
		MinDistance = 999999
		for g = 1 to GroupCnt do 
			for j = 1 to g do 
				if GroupList[g].MinDist[j] < MinDistance then MinDistance = GroupList[g].MinDist[j]
		
		for g = 1 to GroupCnt do
		(
			format "parsing group %\n" g
			progressTest.prog.value = 0
			progressTest.groupid.text = "creating group " + (g as string)
			Lif = LayerManager.getLayerFromName ("group_" + (g as string))
			if Lif == undefined then
			(
				Lif = LayerManager.newLayer()
				Lif.setname ("group_" + (g as string))
			)
			
			for i = 1 to TestPointsNum.value where not UsedPoints[i] do
			(
				p = particlePos PA i
				progressTest.prog.value = (100.*i)/TestPointsNum.value
				if p == undefined then exit
				
				UseThisPoint = true
				
				for j = 1 to g do
				(
					for c in CreatedObjectList[j] do
					(
						di = distance c.position p
						if di < MinDistance then (UsedPoints[i] = true; UseThisPoint = false; exit)
						if di < GroupList[g].MinDist[j] then (UseThisPoint = false; exit)
					)
					if not UseThisPoint then exit
				)
				
				if UseThisPoint then
				(
					sob = GroupList[g].obj[random 1 GroupList[g].obj.count]
					obj = instance sob.RefObject
					Lif.addnode obj
					setuserpropbuffer obj (getuserpropbuffer sob.RefObject)
					obj.name = sob.RefObject.name
					tm = scalematrix ([1,1,1]*(random sob.scale.x sob.scale.y)) * transmatrix [0,0,sob.ZOffset]
					if sob.RandomRotation then tm *= rotateZMatrix (random 0 360)
					if sob.AlignNormals then
					(
						r = ray (p + [0,0,100]) [0,0,-1]
						ir = intersectray TerrainPick.object r
						if ir != undefined then
						(
							tm *= matrixfromnormal ir.dir
						)
					)
					
					tm *= transmatrix p
					obj.transform = tm
					UsedPoints[i] = true
					append CreatedObjectList[g] obj
					CreatedCnt += 1
				)
			)
		)
		
		DestroyDialog progressTest
		delete PA
		EndTime = timestamp()
		format "% objects are created\ntime = % sec\n" CreatedCnt ((EndTime-StartTime)/1000.)
		LastCount.text = "-------------- " + (CreatedCnt as string) + " Objects was created  -----------------"
	)
	
	on Create pressed do
	(
		clearlistener()
		GenerateObjects()
	)
	
	on DeleteLast pressed do
	(
		for a in CreatedObjectList do
			for i in a do 
				if isvalidnode i then delete i
	)
	
--------------------------------------------------------- Mouse
	tool PointCreator
	(
		local p, createpoint
		
		fn createpoint =
		(
			local r = mapScreenToWorldRay viewPoint
			local ir = intersectRay TerrainPick.object r
			if ir!=undefined then
			(
				local p = ir.pos, tm
				local sob = case MouseUseSelected.state of
				(
					1: GroupList[SprGroupID.value].obj[random 1 GroupList[SprGroupID.value].obj.count]
					2: GroupList[SprGroupID.value].obj[InGroupObjectsList.selection]
					3: if selection.count == 0 then undefined else ObjectStruct RefObject:selection[random 1 selection.count] RandomRotation:false AlignNormals:false ZOffset:0 
					default: undefined
				)
				if sob == undefined then return undefined
					
				local obj = if MouseUseSelected.state!=3 or shiftKey then instance sob.RefObject else sob.RefObject
				setuserpropbuffer obj (getuserpropbuffer sob.RefObject)
				obj.name = sob.RefObject.name

				tm = scalematrix ([1,1,1]*(random sob.scale.x sob.scale.y)) * transmatrix [0,0,sob.ZOffset]
				if xor sob.RandomRotation ctrlKey then tm *= rotateZMatrix (random 0 360)
				if xor sob.AlignNormals altKey then tm *= matrixfromnormal ir.dir
				tm *= transmatrix p
				obj.transform = tm
				
				if MouseUseSelected.state != 3 then
				(
					Lif = LayerManager.getLayerFromName ("group_" + (SprGroupID.value as string))
					if Lif == undefined then
					(
						Lif = LayerManager.newLayer()
						Lif.setname ("group_" + (SprGroupID.value as string))
					)
					Lif.addnode obj
				)
			)
		)

		on mousePoint clickno do
		(
			if not clickno == 1 then createPoint()
		)
		
		on mouseMove clickno do 
		(
		)
	)

	on MouseCreate pressed do
	(
		if not isvalidnode TerrainPick.object then messagebox "select terrain object"
		else
			if GroupList[SprGroupID.value].obj.count == 0 and MouseUseSelected.state != 3 then messagebox "select objects in current group id"
			else
				startTool PointCreator
	)

	
) -- roll

try (closerolloutfloater  XRayCloner_flo) catch()
XRayCloner_flo = newRolloutFloater "" 360 600 820 60
addRollout  XRayCloner_rol XRayCloner_flo
addRollout ExportSceneStatic_rol XRayCloner_flo rolledup:true
addRollout renderLod_rol XRayCloner_flo rolledup:true