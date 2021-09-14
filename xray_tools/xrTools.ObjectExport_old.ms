-------------------------------------------------------------------------------------------------------------------------------------------
-- X-Ray SDK object export ver. 20
-- by Den-Stash
-------------------------------------------------------------------------------------------------------------------------------------------

rollout xray_export_statics_rol "x-ray *.object export ver.20"
(

group "static"
(
button export_stat_btn "export static" width:160
checkbox batch_export "batch export" align:#left
dropdownlist StaticObjectType items:#("Static", "Multiple Usage","HOM","Sound Occluder") selection:1 tooltip:""
--label lbl_1 "weld distance" align:#left across:2
--spinner weld_value range:[0,100000,0.0] scale:.001 width:60 align:#right
)

group "skin"
(
button export_skin_btn "export skin" width:160
--checkbox ModelShaders "export models shaders" align:#left
checkbox ExportShapes "export shapes" align:#left enabled:false
)

--group "skin export rigid"
--(
--checkbox UseRigidExp "use rigid mode" align:#left
--button MarkAsCollision "get collision from selection" width:160
--button ConvertToShape "convert selection to collision" width:160
--radiobuttons ConvertType labels:#("box","sph","cyl") columns:3
--)

group ""
(
label lbl_0 "scale object" align:#left across:2
spinner scale_value range:[0,100000,1] scale:.001 width:60 align:#right
dropdownlist SGExportType items:#("Smoothing: Type #1", "Smoothing: Type #2") selection:1 tooltip:""
)

group "collision shapes"
(
	checkbox useShapes "export collision shapes" checked:true
	label lbl_sh1 "create object"
	button shapeCreateSphere "sphere" across:3 width:50 align:#left
	button shapeCreateCyl "cylinder" width:50 align:#center
	button shapeCreateBox "box" width:50 align:#right
	label lbl_sh2 "size" align:#left across:2
	spinner shapeSize range:[0,100000,.5] scale:.01 width:60 align:#right
)

local MaterialList, ShapeList

-------------------------------------------------------------------------------------------------------------------------------------------
fn writePoint f p =
(
	writefloat f p.x
	writefloat f p.z
	writefloat f p.y
)

fn writePointS f p s =
(
	writefloat f (p.x*s)
	writefloat f (p.z*s)
	writefloat f (p.y*s)
)

fn GetSG v =
(
	local n = 0, k = v
	while k >= 1 do (
		k/=2
		n += 1
	)
	
	n
)


fn GetSmoothByOpenEdge f obj =
(
	local Opened = meshop.getOpenEdges obj
	local s = #(4,2,1)
	local i, j, k
	
	for i = 1 to obj.numfaces do
	(
		--FaceSG = getFaceSmoothGroup obj i
		sg = 0
		
		for j = 1 to 3 do
		(
			ei = (i-1)*3 + j
			if Opened[ei] then sg += s[j]
		)

		writelong f sg
	)
)

fn GetSmoothByEdge2 f Sob =
(
	local obj = copy Sob
	local Opened = meshop.getOpenEdges obj
	local s = #(4,2,1)
	local i, j, k
	local FGroups = for i = 1 to 32 collect #{}
	
	for i = 1 to obj.numfaces do
	(
		sg = GetSG(getFaceSmoothGroup obj i) + 1
		append FGroups[sg] i
	)
	
	for g in FGroups where g.numberset > 0 do
		meshop.detachFaces obj g delete:true asMesh:false
	
	GetSmoothByOpenEdge f obj
	delete obj
)

-------------------------------------------------------------------------------------------------------------------------------------------
fn write_single_mesh f sobj ExportSkinMode ExportRigidMode =
(
	local i, j, k
	local Result = #() -- [1] = used matID as bitarray
	local obj = copy sobj
	
	local ExportSkin = false
	local BoneTabIndex = #()
	local SkinMod = sobj.modifiers[1]
	
	max modify mode
	
	if classof SkinMod == skin and ExportSkinMode then
	(
		select obj
		convertToMesh obj
		
		format "\t\tcheck mapping: "
		ts = timestamp()
		local tused = #()
		N = getNumTVerts obj
		wrongMapping = false
		
		for i = 1 to obj.numfaces do
		(
			fv = getface obj i
			tv = gettvface obj i
			
			for j = 1 to 3 do
			(
				if tused[tv[j]] == undefined then
				(
					tused[tv[j]] = fv[j]
				)
				else
					if tused[tv[j]] == fv[j] then continue
					else
					(
						N += 1
						setnumtverts obj N true
						settvert obj N (gettvert obj tv[j])
						tv[j] = N
						settvface obj i tv
						wrongMapping = true
					)
			)
		)
		
		if wrongMapping then format "texture verts was rebuilded [done at % sec]\n" ((timestamp() - ts)/1000.)
		else format "OK [done at % sec]\n" ((timestamp() - ts)/1000.)
		
		select sobj
		ExportSkin = true
		local NumBones = skinOps.GetNumberBones SkinMod
		max modify mode
	)
	else convertToMesh obj
	
	if ExportRigidMode then
	(
		ExportSkin = true
		format "\t\tRigid export\n"
	)
	
	--if not (meshop.getmapsupport obj 1) then meshop.setmapsupport obj 1 true
	
	if not ExportSkin then --										Prepare mesh
	(
		--if weld_value.value > 0.0 then meshop.weldVertsByThreshold obj #all weld_value.value
		meshOps.removeIsolatedVerts obj
	)
	
	meshop.buildMapFaces obj 1 keep:true
	if obj.numtverts < obj.numverts then meshop.setNumMapVerts obj 1 obj.numverts keep:true
	
	local i, j, k, tempSizeOfs1, tempSizeOfs2, p

	writelong f 0x1000	-- 											EMESH_CHUNK_VERSION
	writelong f 2
	writeshort f 17
	
	writelong f 0x1001	-- 											EMESH_CHUNK_MESHNAME
	writelong f (sobj.name.count + 1)
	writestring f sobj.name
	
	writelong f 0x1004	-- 											EMESH_CHUNK_BBOX
	writelong f 24
	writePoint f (obj.min*scale_value.value)
	writePoint f (obj.max*scale_value.value)
	
	writelong f 0x1002	-- 											EMESH_CHUNK_FLAGS
	writelong f 1
	writebyte f 5
	
	writelong f 0x1010	-- 											EMESH_CHUNK_OPTIONS
	writelong f 8
	writelong f 0
	writelong f 0
	
	--format "\t\twriting verts\n" -- 								EMESH_CHUNK_VERTS
	writelong f 0x1005
	local NumVerts = obj.numverts
	writelong f (NumVerts*12 + 4)
	writelong f NumVerts
	for i = 1 to NumVerts do writePoint f ((getvert obj i)*scale_value.value)
	
	--format "\t\twriting faces\n" 									-- EMESH_CHUNK_FACES
	writelong f 0x1006
	local NumFaces = obj.numfaces
	writelong f (NumFaces*24 + 4)
	writelong f NumFaces 
	
	for i = 1 to NumFaces do
	(
		j = getface obj i
		k = getTVFace obj i
		writelong f ((j.x as integer) - 1)
		writelong f ((k.x as integer) - 1)
		writelong f ((j.z as integer) - 1)
		writelong f ((k.z as integer) - 1)
		writelong f ((j.y as integer) - 1)
		writelong f ((k.y as integer) - 1)
	)
	
	writelong f 0x1013												-- EMESH_CHUNK_SG
	writelong f (NumFaces*4)
	
	if SGExportType.selection == 1 then 
		for i = 1 to NumFaces do writelong f (getsg (getFaceSmoothGroup obj i))
	else
		GetSmoothByEdge2 f obj
	
																	-- EMESH_CHUNK_VMREFS
	writelong f 0x1008
	local NumTVerts = getNumTVerts obj
	tempSizeOfs1 = ftell f
	writelong f 0
	writelong f NumTVerts 

	local VTable = #(#())
	local TableId = for i = 1 to NumTVerts collect #()
	local TableIndex = for i = 1 to NumTVerts collect #()
	local ITable1 = #(), ITable2 = #(), ITable22 = #()
	local TabNames = #()
	local SecondTexTabIndex
	local vused = #{}, tused = #{}
	
	
	for i = 1 to NumFaces do
	(
		fv = getface obj i ; swap fv.y fv.z
		tfv = gettvface obj i ; swap tfv.y tfv.z
		
		for j = 1 to 3 do
		(
			if vused[fv[j]] then
			(
				if not tused[tfv[j]] then
				(
					if SecondTexTabIndex == undefined then (SecondTexTabIndex = VTable.count + 1; VTable[SecondTexTabIndex] = #())
					append VTable[SecondTexTabIndex] tfv[j]
					TableId[tfv[j]][1] = SecondTexTabIndex - 1
					TableIndex[tfv[j]][1] = VTable[SecondTexTabIndex].count
					append ITable2 (fv[j]-1)
					append ITable22 (i-1)
				)
			)
			else
			(
				vused[fv[j]] = true
				append VTable[1] tfv[j]
				TableId[tfv[j]][1] = 0
				TableIndex[tfv[j]][1] = VTable[1].count
				append ITable1 (fv[j]-1)
			)
			
			if ExportSkin and (not tused[tfv[j]]) then
			(
				if ExportRigidMode then
				(
					if BoneTabIndex[1] == undefined then
					(
						BoneTabIndex[1] = VTable.count + 1
						VTable[BoneTabIndex[1]] = #()
						TabNames[BoneTabIndex[1]] = xrToolsUtil.renameBone (ShapeList[1].name)
					)
					append VTable[BoneTabIndex[1]] 1.0
					append TableId[tfv[j]] (BoneTabIndex[1] - 1)
					append TableIndex[tfv[j]] VTable[BoneTabIndex[1]].count
				)
				else
				(
					nb = skinOps.GetVertexWeightCount SkinMod fv[j]
					for k = 1 to nb do
					(
						bid = skinOps.GetVertexWeightBoneID SkinMod fv[j] k
						bw = skinOps.GetVertexWeight SkinMod fv[j] k -- bid
						if BoneTabIndex[bid] == undefined then
						(
							BoneTabIndex[bid] = VTable.count + 1
							VTable[BoneTabIndex[bid]] = #()
							TabNames[BoneTabIndex[bid]] = xrToolsUtil.renameBone (skinOps.GetBoneName SkinMod bid 0)
						)
						append VTable[BoneTabIndex[bid]] bw
						append TableId[tfv[j]] (BoneTabIndex[bid] - 1)
						append TableIndex[tfv[j]] VTable[BoneTabIndex[bid]].count
					)
				)
			)
			tused[tfv[j]] = true
		)
	)
	
	for i = 1 to NumTVerts do
	(
		writebyte f TableId[i].count
		
		for j = 1 to TableId[i].count do
		(
			writelong f TableId[i][j]
			writelong f (TableIndex[i][j]-1)
		)
	)
	
	
	tempSizeOfs2 = ftell f
	fseek f tempSizeOfs1 #seek_set
	writelong f (tempSizeOfs2 - tempSizeOfs1 - 4)
	fseek f tempSizeOfs2 #seek_set
	
	
	writelong f 0x1009														-- EMESH_CHUNK_SFACE
	tempSizeOfs1 = ftell f
	writelong f 0
	writeshort f 0	-- num materials
	local NumMats = 0
	local mat = obj.material
	local mats = if classof mat == multimaterial then mat else #(mat)
	local N = mats.count
	local surfa = #()
	Result[1] = #{}
	
	for i = 1 to NumFaces do
	(
		id = getFaceMatID obj i
		id = (mod (id-1) N) + 1
		if surfa[id] == undefined then (surfa[id] = #{}; append Result[1] id)
		surfa[id][i] = true
	)
	
	for i in Result[1] do
	(
		if mats[i] != undefined then 
		(
			writestring f mats[i].name
			if finditem MaterialList mats[i] == 0 then append MaterialList mats[i]
		)
		else 
		(
			writestring f "undefined_material"
			if finditem MaterialList "undefined_material" == 0 then append MaterialList "undefined_material"
		)
		writelong f surfa[i].numberset
		for j in surfa[i] do writelong f (j-1)
	)
	
	tempSizeOfs2 = ftell f
	fseek f tempSizeOfs1 #seek_set
	writelong f (tempSizeOfs2 - tempSizeOfs1 - 4)
	writeshort f Result[1].numberset
	fseek f tempSizeOfs2 #seek_set
	
	
	writelong f 0x1012														-- EMESH_CHUNK_VMAPS_2
	tempSizeOfs1 = ftell f
	writelong f 0	-- size
	writelong f VTable.count	-- tables count
	
	for i = 1 to VTable.count do
	(
		if i == 1 or i == SecondTexTabIndex then	-- texture table
		(
			writestring f "Texture"
			writebyte f 2 -- type
			writeshort f (if i == 1 then 0 else 1)
			writelong f VTable[i].count
			
			for j in VTable[i] do
			(
				p = gettvert obj j
				writefloat f p.x
				writefloat f (1 - p.y)
			)
			
			if i == 1 then for j in ITable1 do writelong f j
			else
			(
				for j in ITable2 do writelong f j
				for j in ITable22 do writelong f j
			)
		)
		else
		(
			-- bones
			writestring f TabNames[i]
			writebyte f 1
			writeshort f 256
			writelong f VTable[i].count
			
			for j in VTable[i] do writefloat f j
			for j in VTable[i] do writefloat f 0
		)
	)
	
	tempSizeOfs2 = ftell f
	fseek f tempSizeOfs1 #seek_set
	writelong f (tempSizeOfs2 - tempSizeOfs1 - 4)
	fseek f tempSizeOfs2 #seek_set
	
	delete obj
	format "\t\tmesh [%] done\n" sobj.name
	return Result
)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
fn export_object f sobj ExportSkinMode ExportRigidMode =
(
	local obj, curOfs
	MaterialList = #()
	
	for obj in sobj where obj.material != undefined do
	(
		mats = if classof obj.material == multimaterial then obj.material else #(obj.material)
		for m in mats do if finditem MaterialList m == 0 then append MaterialList m
	)
	
	for i = 1 to MaterialList.count-1 where MaterialList[i] != undefined do
		for j = i+1 to MaterialList.count where MaterialList[j] != undefined do
			if stricmp MaterialList[i].name MaterialList[j].name == 0 then assignNewName MaterialList[j]
	
	MaterialList = #()
	
	--format "writing header\n" --------------------------------------------------------------- write file header
	writelong f 0x7777
	writelong f 0
	
	writelong f 0x0900	-- EOBJ_CHUNK_VERSION
	writelong f 2
	writeshort f 16
	
	writelong f 0x0912	-- EOBJ_CHUNK_USERDATA
	writelong f 1
	writebyte f 0
	
	writelong f 0x0925	-- EOBJ_CHUNK_LOD_REF
	writelong f 1
	writebyte f 0
	
	local ExportSkin = false
	local NumBones
	
	if ExportSkinMode then
	(
		local SkinMod = sobj[1].modifiers[1]
		if classof SkinMod == skin then
		(
			ExportSkin = true
			NumBones = skinOps.GetNumberBones SkinMod
		)
	)
	
	if ExportRigidMode then
	(
		ExportSkin = true
		NumBones = ShapeList.count
	)
	
	writelong f 0x0903	-- EOBJ_CHUNK_FLAGS
	writelong f 4
	EOBJ_CHUNK_FLAGS = case StaticObjectType.selection of
	(	1: 0
		2: 20
		3: 8
		4: 32
		default: 0
	)
	writelong f (if ExportSkin then 1 else EOBJ_CHUNK_FLAGS)
	
	format "\twriting meshes\n" ------------------------------------------------------------------------------------------ MESHES
	writelong f 0x0910	-- EOBJ_CHUNK_MESHES
	local ChangeOffset_Meshes = ftell f
	writelong f 0
	
	for i = 1 to sobj.count where superclassof sobj[i] == GeometryClass do
	(
		writelong f (i-1)		-- MESH_INDEX
		ChangeOffset_singleMesh = ftell f
		writelong f 0
		
		wsm = write_single_mesh f sobj[i] ExportSkin ExportRigidMode
		
		curOfs = ftell f
		fseek f ChangeOffset_singleMesh #seek_set
		writelong f (curOfs - ChangeOffset_singleMesh - 4)
		fseek f curOfs #seek_set
	)
	
	curOfs = ftell f
	fseek f ChangeOffset_Meshes #seek_set
	writelong f (curOfs - ChangeOffset_Meshes - 4)
	fseek f curOfs #seek_set
	
	writelong f 0x0907																		--------------------------- MATERIALS
	local ChangeOffset_materials = ftell f	
	writelong f 0
	writelong f MaterialList.count -- materials count

	local dm, dfile = "", str = "", n
	
	for mat in MaterialList do
	(
		if mat == "undefined_material" then
		(
			writestring f "undefined_material"
			for j = 1 to 3 do writestring f "default"
			writestring f "mtl\\mtl_rja_01"
			writestring f "Texture"
			writelong f 0 -- Double side
			writelong f 0x112				-- Unk flags 1
			writelong f 0x1					-- Unk flags 2
			continue
		)
		
		writestring f mat.name
		
		/*
		if ModelShaders.checked then
		(
			writestring f "models\\model"
			writestring f "default"
			writestring f "default_object"
		)
		else
		*/
		
		doubleSide = false
		
		if classof mat == S_T_A_L_K_E_R_Mtl then 
		(
			if mat.EShaderByName != undefined then writestring f mat.EShaderByName else writestring f "default"
			if mat.CShaderByName != undefined then writestring f mat.CShaderByName else writestring f "default"
			if mat.GameMtlByName != undefined then writestring f mat.GameMtlByName else writestring f "default"
			doubleSide = mat.twoSided
		)
		else
			if (xrToolsUtil.HasShadersCA mat) then
			(
				writestring f mat.EShader
				writestring f mat.CShader 
				writestring f mat.GameMaterial
				doubleSide = mat.twoSided
			)
			else
			(
				for j = 1 to 3 do writestring f "default"
				if classof mat == standard then doubleSide = mat.twoSided
			)
		
		dm = try (mat.diffuseMap) catch (undefined)
		dfile = "mtl\\mtl_rja_01"
		
		if dm != undefined then
		(
			dfile = if dm.filename != undefined then getfilenamefile dm.filename else "mtl_rja_01"
			if dfile == "" or dfile == undefined then dfile = "mtl_rja_01"
			n = findstring dfile "_"
			if n != undefined then dfile = (substring dfile 1 (n-1)) + "\\" + dfile
		)
		else format "#warning !!! material % hasn't diffusemap property\n" mat
		
		writestring f dfile
		writestring f "Texture"
		writelong f (if doubleSide then 1 else 0) -- Double side
		writelong f 0x112				-- Unk flags 1
		writelong f 0x1					-- Unk flags 2
	)
	
	curOfs = ftell f
	fseek f ChangeOffset_materials #seek_set
	writelong f (curOfs - ChangeOffset_materials - 4)
	fseek f curOfs #seek_set
	
	
	
	if ExportSkin then
	(
		writelong f 0x0921																		-- BONES
		local ChangeOffset_bones = ftell f	
		writelong f 0
		
		for i = 1 to NumBones do
		(
			writelong f (i-1)	-- bone index
			ChangeOffset_temp = ftell f
			writelong f 0		-- size
			
			writelong f 1		-- unknown section = 2
			writelong f 2
			writeshort f 2
			
			if ExportRigidMode then
			(
				bname = xrToolsUtil.renameBone ShapeList[i].name
				bob = ShapeList[i]
				pname = if i==1 then "scene_root" else ShapeList[1].name
				paro = if i==1 then undefined else ShapeList[1]
			)
			else
			(
				SceneBoneName = skinOps.GetBoneName SkinMod i 0
				bname = xrToolsUtil.renameBone (SceneBoneName)
				bob = execute ("$'" + SceneBoneName + "'")
				--pname = if bob.parent == undefined then "scene_root" else xrToolsUtil.renameBone(bob.parent.name)
				--paro = bob.parent
				
				if bob.parent == undefined then
				(
					pname = "scene_root"
					paro = undefined
				)
				else
				(
					ParentInList = false
					for j = 1 to NumBones do 
						if (skinOps.GetBoneName SkinMod j 0) ==  bob.parent.name then (ParentInList = true; exit)
					if ParentInList then
					(
						pname = xrToolsUtil.renameBone(bob.parent.name)
						paro = bob.parent
					)
					else
					(
						pname = "scene_root"
						paro = undefined
					)
				)
				--format "SceneBoneName % , bname % , bob % , pname %, paro %\n"  SceneBoneName bname bob pname paro
			)
			
			writelong f 2
			writelong f (2*bname.count + pname.count + 3)
			writestring f bname
			writestring f pname
			writestring f bname
			
			writelong f 3
			writelong f 28
			ttm = if paro == undefined then (orthogonalize bob.transform) else (orthogonalize bob.transform)*(inverse (orthogonalize paro.transform))
			writepointS f ttm.position scale_value.value
			rot = quattoeuler ttm.rotation order:4
			rx = degtorad(rot.x)
			ry = degtorad(rot.y)
			rz = degtorad(rot.z)
			writefloat f -ry
			writefloat f -rz
			writefloat f -rx
			writefloat f 0.1
			
			writelong f 2
			writelong f (bname.count + 1)
			writestring f bname
				
			writelong f 4
			sob = execute("$'shape_" + SceneBoneName + "'")
			if useShapes.checked == false then sob = undefined
			--BoneMat = getuserprop bob "Material" ; if BoneMat == undefined then BoneMat = "default_object"
			BoneMat = "default_object"
			if sob != undefined then
			(
				if classof sob.material == standard then
					if (xrToolsUtil.HasShadersCA sob.material) then
						BoneMat = sob.material.GameMaterial
				format "\tfound shape % (material: %)\n" SceneBoneName BoneMat
			)
			writelong f (BoneMat.count+1)
			writestring f BoneMat --"default_object"
			
			if sob == undefined then
			(
				
				writelong f 5
				writelong f 112
				writeshort f 0 --shape_type
				writeshort f 0 -- shape_flags
				writepoint f [1,0,0] -- tm.row1
				writepoint f [0,0,1] -- tm.row2
				writepoint f [0,1,0] -- tm.row3
				writepoint f [0,0,0] -- BoxCenter
				writepoint f [0,0,0] -- BoxHalfSize
				writepoint f [0,0,0] -- SphereCenter
				writefloat f 0 -- SphereRadius
				writepoint f [0,0,0]  -- CylCenter 
				writepoint f [0,0,0]  --CylDir
				writefloat f 0 --CylHeight 
				writefloat f 0 --CylRadius
			)
			else
			(
				if classof sob == XRayCollision then shape_type = sob.sType
				else	if classof sob == Sphere then shape_type = 2
					else if classof sob == Cylinder then shape_type = 3
						else shape_type = 1
				
				writelong f 5
				writelong f 112
				writeshort f shape_type ; 0 --shape_type
				writeshort f 0 -- shape_flags
				
				tm = (orthogonalize sob.transform)*(inverse (orthogonalize bob.transform))
				writePoint  f tm.row1
				writePoint  f tm.row3
				writePoint  f tm.row2
				
				writepointS f (sob.center*(inverse (orthogonalize bob.transform))) scale_value.value -- BoxCenter
				if classof sob == XRayCollision then 
				(
					writefloat f (sob.width*scale_value.value)
					writefloat f (sob.height*scale_value.value)
					writefloat f (sob.length*scale_value.value)
				)
				else
				(
					tms = sob.transform
					sob.rotation = quat 0 0 0 1
					writePointS  f ((sob.max - sob.min)/2.) scale_value.value
					sob.transform = tms
				)
					
				writepointS f tm.row4 scale_value.value -- SphereCenter
				curScl = amax sob.scale.x sob.scale.y sob.scale.z
				if classof sob == XRayCollision then writefloat f (sob.sradius*scale_value.value*curScl)
				else if shape_type == 2 then writefloat f (sob.radius*scale_value.value*curScl)
					else writefloat f ((sob.max.z - sob.min.z)*scale_value.value*curScl)
				
				if classof sob == XRayCollision then writePointS f tm.row4 scale_value.value
				else if shape_type == 3 then writePointS f  (([0,0,sob.height/2]*sob.transform)*(inverse (orthogonalize bob.transform))) scale_value.value
					else writePointS f tm.row4 scale_value.value
				
				--writePointS  f (in coordsys bob sob.dir) scale_value.value
				writePoint  f (in coordsys bob sob.dir)
				if classof sob == XRayCollision then
				(
					writefloat f (sob.cheight*scale_value.value*curScl)
					writefloat f (sob.cradius*scale_value.value*curScl)
				)
				else 
				(
					if shape_type == 3 then writefloat f (sob.height*scale_value.value*curScl) else writefloat f ((sob.max.z - sob.min.z)*scale_value.value*curScl)
					if shape_type == 3 then writefloat f (sob.radius*scale_value.value*curScl) else writefloat f ((sob.max.z - sob.min.z)*scale_value.value*curScl)
				)
			)
			
			writelong f 8
			writelong f 4
			writefloat f 0
			
			writelong f 6
			writelong f 60
			writelong f 0 -- joint_type
			for k = 1 to 3 do
			(
				writefloat f 0 -- axis min
				writefloat f 0 -- axis max
				writefloat f 1 -- SprFactor
				writefloat f 1 -- DumpFactor
			)
			writefloat f 1 -- SprFactor				
			writefloat f 1 -- DumpFactor
			
			writelong f 9  -- unk floats
			writelong f 8
			writefloat f 0
			writefloat f 0
			
			writelong f 16	-- unk float
			writelong f 4
			writefloat f 0.
			
			writelong f 7	-- mass
			writelong f 16
			writefloat f 10
			if sob == undefined then writepoint f [0,0,0] -- center mass
			else writePointS f  (sob.center*(inverse (orthogonalize bob.transform))) scale_value.value
			
			curOfs = ftell f
			fseek f ChangeOffset_temp #seek_set
			writelong f (curOfs - ChangeOffset_temp - 4)
			fseek f curOfs #seek_set
		)
		
		curOfs = ftell f
		fseek f ChangeOffset_bones #seek_set
		writelong f (curOfs - ChangeOffset_bones - 4)
		fseek f curOfs #seek_set
		
	)
	
	
	
	
	writelong f 0x0922																		-- FILE VERSION
	writelong f 10
	writebyte f 0
	writelong f 0
	writebyte f 0
	writelong f 0
	
	-------------
	curOfs = ftell f
	fseek f 4 #seek_set
	writelong f (curOfs - 8)
)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
on shapeCreateSphere pressed do
(
	bob = selection[1]
	newname = if bob == undefined then "shape_" else "shape_" + bob.name
	tm = if bob == undefined then matrix3 1 else orthogonalize bob.transform
	s = sphere radius:(shapeSize.value/2) name:newname xray:true
	s.transform = tm
	select s
)

on shapeCreateCyl pressed do
(
	bob = selection[1]
	newname = if bob == undefined then "shape_" else "shape_" + bob.name
	tm = if bob == undefined then matrix3 1 else orthogonalize bob.transform
	s = cylinder radius:(shapeSize.value/2) height:shapeSize.value name:newname xray:true
	s.transform = tm
	select s
)

on shapeCreateBox pressed do
(
	bob = selection[1]
	newname = if bob == undefined then "shape_" else "shape_" + bob.name
	tm = if bob == undefined then matrix3 1 else orthogonalize bob.transform
	s = box length:(shapeSize.value/2) height:(shapeSize.value/2) width:(shapeSize.value/2) name:newname xray:true
	s.pivot = s.center
	resetXForm s
	collapsestack s
	s.transform = tm
	select s
)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
on MarkAsCollision pressed do
(
	ShapeList = for obj in selection collect obj
	MarkAsCollision.text = (ShapeList.count as string) + " objects marked as collision"
)

on MarkAsCollision rightclick do
(
	ShapeList = #()
	MarkAsCollision.text = "get collision from selection"
)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
on ConvertToShape pressed do
(
	objs = selection as array
	
	for obj in objs where superclassof obj == geometryclass do
		with redraw off
		(
			tm = orthogonalize obj.transform
			obj.transform *= inverse tm
			c = obj.center
			obj.pos -= c
			bnd = (obj.max - obj.min)/2.
			
			b = XRayCollision 	stype:ConvertType.state \
								width:bnd.x length:bnd.y height:bnd.z \
								sradius:(((amax bnd.x bnd.y bnd.z) + (amin bnd.x bnd.y bnd.z))/1.5) \
								cradius:(((amax bnd.x bnd.y) + (amin bnd.x bnd.y))/1.5) cheight:(bnd.z*2) \
								pos:c name:obj.name xray:true color:(color 120 120 120)
			b.transform *= tm
			delete obj
		)
)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
on export_skin_btn pressed do
(
	if selection.count != 1 then messagebox "select just one object to export"
	else
	(
		InitialPath = getinisetting (scriptspath + "xr_scripts_settings.txt") "paths" "InitialSkinExportPath" + "\\"
		try (fname = getsavefilename types:("xray_sdk_model|*.object|") filename:InitialPath) 
		catch (fname = undefined ; messagebox "unknown bug:\ntry type file name with extension *.object")
		if fname != undefined then
		(
			clearlistener()
			f = fopen fname "wb"
			ts = timestamp()
			with undo off
				--with redraw off
				(
					format "exporting %\n" fname
					try (export_object f #(selection[1]) true false) 
					catch( format "### export failed\n%\n" (getcurrentexception()) ) -- UseRigidExp.checked
				)
			fclose f
			format "done at % sec\n" ((timestamp() - ts)/1000.)
		)
	)
)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
on export_stat_btn pressed do
(
	InitialPath = (getinisetting (scriptspath + "xr_scripts_settings.txt") "paths" "InitialStaticExportPath") + "\\"
	ObjectsPath = getinisetting (scriptspath + "xr_scripts_settings.txt") "paths" "last_objects_path"
	
	if batch_export.checked then
	(
		if selection.count == 0 then messagebox "select objects to export"
		else
		(
			fpath = getsavepath initialDir:InitialPath
			if fpath != undefined then
			(
				tts = timestamp()
				clearlistener()
				
				with undo off
					with redraw off
						for eobj in selection do
						(
							fname = fpath + "\\" + eobj.name + ".object"
							f = fopen fname "wb"
							if f == undefined then format "### error : cant create file %\n" fname
							else
							(
								format "exporting %\n" fname
								--ts = timestamp()
								--try (export_object f #(eobj) false false) catch ( format "### export failed\n%\n" (getcurrentexception()) )
								export_object f #(eobj) false false
								setuserprop eobj "ref_name" ((substring (getfilenamepath fname) (ObjectsPath.count+2) -1) + (getfilenamefile fname))
								fclose f
								--format "done at % sec\n" ((timestamp() - ts)/1000.)
							)
						)
				
				format "total time % sec\n" ((timestamp() - tts)/1000.)
			)
		)
	)
	else
	(
		if selection.count == 0 then messagebox "select object to export"
		else
		(
			try ( fname = getsavefilename types:("xray_sdk_model|*.object|") filename:InitialPath ) 
			catch (fname = undefined ; messagebox "unknown bug:\ntry type file name with extension *.object")
			if fname != undefined then
			(
				clearlistener()
				f = fopen fname "wb"
				ts = timestamp()
				eobj = selection as array
				with undo off
					with redraw off
					(
						format "exporting %\n" fname
						--ts = timestamp()
						--try (export_object f eobj false false) catch ( format "### export failed\n%\n" (getcurrentexception()) )
						export_object f eobj false false
						--format "done at % sec\n" ((timestamp() - ts)/1000.)
						for obj in eobj do setuserprop obj "ref_name" ((substring (getfilenamepath fname) (ObjectsPath.count+2) -1) + (getfilenamefile fname))
					)
				fclose f
				format "done at % sec\n" ((timestamp() - ts)/1000.)
			)
		)
	)
)

) -- roll

try (closeRolloutFloater xray_export_statics_flo) catch ()
xray_export_statics_flo = newRolloutFloater "x-ray tools" 200 400 120 130
addRollout  xray_export_statics_rol xray_export_statics_flo