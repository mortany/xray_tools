fn xray_check_scene_materials fname EngineMaterial CompileMaterial GameMaterial MaterialDoubleSide =
(
	local m, mat
	
	for mat in sceneMaterials do
	(
		if classof mat != multimaterial then mats = #(mat) else mats = mat
		for m in mats do
		(
			case (classof m) of
			(
				--Standard:	dm = mat.diffusemap
				S_T_A_L_K_E_R_Mtl:	
					(
						dm = m.diffusemap
						--format "check %, %\n" dm.filename fname
						if dm!=undefined then
							if dm.filename != undefined then
								if (stricmp fname dm.filename) == 0 and m.EShaderByName == EngineMaterial and 
									m.CShaderByName == CompileMaterial and m.GameMtlByName == GameMaterial and 
									(m.twoSided == (MaterialDoubleSide!=0)) then 
									(
										--format "material replaced %\n" fname
										return m
									)
					)
				default:	()
			)
		)
	)
	
	return undefined
)

fn load_object f filesize LoadMats LoadRec = 
(
		sectionId = readlong f ; if sectionId != 0x7777 then ( format "\n### Unsupported file version\n" ; return #() )
		SectionSize = readlong f #unsigned
		--format "section [id = 0x%, size=%] at 0\t\t| EOBJ_CHUNK_MAIN\n" (bit.intashex sectionId) SectionSize
	
		fn ReadPoint f = 
		(
			local x = readfloat f
			local z = readfloat f
			local y = readfloat f
			return [x, y, z]
			--return -[x, z, y]
		)
		
		local vmas = #(), fmas = #(), tvmas = #(), tfmas = #(), BugReport = #()
		local TexPath = "E:\\X-Ray CoP SDK\\editors\\gamedata\\textures" --TPathTxt.text --TexturePath
		local SectionEndOfs, Result = #()
		local TexTabID1, TexTabID2
		local EOBJ_CHUNK_FLAGS, EOBJ_CHUNK_VERSION, EOBJ_CHUNK_USERDATA, EOBJ_CHUNK_LOD_REF
		local VTable, ITable, VTable2 , BoneNamesList, XTable = #()
		
		while true do
		(
				CurPos = ftell f
				if CurPos >= filesize then exit --( format "end reached at %\n" CurPos ; exit )
				sectionId = readlong f ; if sectionId == undefined then ( format "\n# eof\n" ; exit )
				SectionSize = readlong f #unsigned
				StartPos = ftell f
				SectionEndOfs = StartPos + SectionSize
				if SectionEndOfs > filesize then (format "\n### NOT EXPECTED END\n" ; exit )
				
				--format "section [id = 0x%, size=%] at %\t\t|" (bit.intashex sectionId) SectionSize (StartPos-8)
				
				case sectionId of
				(
					0x7777:
						(
								--format " EOBJ_CHUNK_MAIN\n"
						)
					0x0900:
						(
								EOBJ_CHUNK_VERSION = readshort f
								--format " EOBJ_CHUNK_VERSION (16 supported) = %\n" EOBJ_CHUNK_VERSION
								if EOBJ_CHUNK_VERSION != 16 then ( format "\n### Unsupported file version\n" ; return #() )
						)
					0x0912:
						(
								EOBJ_CHUNK_USERDATA = readstring f
								--format " EOBJ_CHUNK_USERDATA = %\n" EOBJ_CHUNK_USERDATA
						)
					0x0925:
						(
								EOBJ_CHUNK_LOD_REF = readstring f
								--format " EOBJ_CHUNK_LOD_REF = %\n" (trimright EOBJ_CHUNK_LOD_REF)
								fseek f SectionEndOfs #seek_set
						)
					0x0903:
						(
								EOBJ_CHUNK_FLAGS = readlong f
								--format " EOBJ_CHUNK_FLAGS = %\n" EOBJ_CHUNK_FLAGS
						)
					0x0910:
						(
								--if SectionSize > 0 then format " EOBJ_CHUNK_MESHES\n"
								MeshesEndOfs = SectionSize + (ftell f)
								Result[1] = #()
								Result[2] = #()
																
								while true do
								(
										if (ftell f) >= MeshesEndOfs then exit --( format "\n.......meshes loaded\n\n" ; exit)
										MeshIndex = readlong f --; format "\nLOADING MESH %.......\n" MeshIndex
										CurMeshSize = readlong f
										CurMeshSize += ftell f
										LoadCurrentMesh = false
										
										while true do
										(
												CurPos = ftell f
												if CurPos >= CurMeshSize then exit
												sectionId = readlong f ; if sectionId == undefined then break()
												SectionSize = readlong f #unsigned
												StartPos = ftell f
												SectionEndOfs = StartPos + SectionSize
												if SectionEndOfs > CurMeshSize then (exit) --break()
												
												--format "section [id = % (0x%), size=%] at %\t\t|" sectionId (bit.intashex sectionId) SectionSize (StartPos-8)
												
												case sectionId of
												(
													0x1000:
														(
																EMESH_CHUNK_VERSION = readshort f
																--format " EMESH_CHUNK_VERSION = %\n" EMESH_CHUNK_VERSION
														)
													0x1001:
														(
																EMESH_CHUNK_MESHNAME = readstring f --; format " EMESH_CHUNK_MESHNAME = %\n" EMESH_CHUNK_MESHNAME
														)
													0x1004:
														(
																b = for i = 1 to 6 collect (readfloat f)
																--format " EMESH_CHUNK_BBOX %, %\n" EMESH_CHUNK_MESHNAME b
																testpo = [b[1]+LoadRec[1].x, b[3] + LoadRec[1].y, 0]
																if testpo.x>LoadRec[2].x and testpo.x<LoadRec[3].x and testpo.y>LoadRec[2].y and testpo.y<LoadRec[3].y then LoadCurrentMesh = true
																testpo = [b[1]+LoadRec[1].x, b[6] + LoadRec[1].y, 0]
																if testpo.x>LoadRec[2].x and testpo.x<LoadRec[3].x and testpo.y>LoadRec[2].y and testpo.y<LoadRec[3].y then LoadCurrentMesh = true
																testpo = [b[4]+LoadRec[1].x, b[3] + LoadRec[1].y, 0]
																if testpo.x>LoadRec[2].x and testpo.x<LoadRec[3].x and testpo.y>LoadRec[2].y and testpo.y<LoadRec[3].y then LoadCurrentMesh = true
																testpo = [b[4]+LoadRec[1].x, b[6] + LoadRec[1].y, 0]
																if testpo.x>LoadRec[2].x and testpo.x<LoadRec[3].x and testpo.y>LoadRec[2].y and testpo.y<LoadRec[3].y then LoadCurrentMesh = true

														)
													0x1002:
														(
																EMESH_CHUNK_FLAGS = readbyte f
																--format " EMESH_CHUNK_FLAGS = %\n" EMESH_CHUNK_FLAGS
																--if EOBJ_CHUNK_FLAGS != 0 then LoadCurrentMesh = false
														)
													0x1010:
														(
																EMESH_CHUNK_OPTIONS = readstring f --; format "EMESH_CHUNK_OPTIONS = %\n" EMESH_CHUNK_OPTIONS
																fseek f (SectionSize + StartPos) #seek_set
														)
													0x1005:
														(
															if LoadCurrentMesh then
															(
																NumVerts = readlong f #unsigned --; format " EMESH_CHUNK_VERTS [%]" NumVerts
																vmas = for i = 1 to NumVerts collect (ReadPoint f)
															)
														)
													0x1006:
														(
															if LoadCurrentMesh then
															(
																NumFaces = readlong f #unsigned --; format " EMESH_CHUNK_FACES [%]" NumFaces 
																fmas = #(); tfmas = #()
																
																if LoadMats then
																	for i = 1 to NumFaces do
																	(
																			v1 = readlong f
																			tv1 = readlong f
																			v2 = readlong f
																			tv2 = readlong f
																			v3 = readlong f
																			tv3 = readlong f
																			append fmas [v1+1,v3+1,v2+1] --[v1+1,v2+1,v3+1] --[v1+1,v3+1,v2+1]
																			append tfmas [tv1+1,tv3+1,tv2+1] --[tv1+1,tv2+1,tv3+1] --[tv1+1,tv3+1,tv2+1]
																			--format "-- tface % , %\n" i tfmas[tfmas.count]
																	)
																else
																	for i = 1 to NumFaces do
																	(
																			v1 = readlong f
																			tv1 = readlong f
																			v2 = readlong f
																			tv2 = readlong f
																			v3 = readlong f
																			tv3 = readlong f
																			append fmas [v1+1,v3+1,v2+1] --[v1+1,v2+1,v3+1] --[v1+1,v3+1,v2+1]
																	)
																
																m = mesh vertices:vmas faces:fmas
																m.name = EMESH_CHUNK_MESHNAME
																Result[1][MeshIndex+1] = m
																--append Result[2] m.name
																--format " ...... loaded\n"
															)
															else fseek f (SectionSize + StartPos) #seek_set
														)
													0x1013:
														(
																--format " EMESH_CHUNK_SG\n"
																if LoadCurrentMesh then for i = 1 to NumFaces do ( sg = readlong f #unsigned ; setFaceSmoothGroup m i 0 ) --sg )
																else fseek f (SectionSize + StartPos) #seek_set
														)
													0x1008:
														(
																NumVMREFS = readlong f #unsigned
																if LoadMats and LoadCurrentMesh then
																	for i = 1 to NumVMREFS do
																	(
																			--if (ftell f) >= (SectionSize + StartPos) then exit
																			Cnt = readbyte f
																			XTable[i] = for j = 1 to Cnt collect #(readlong f, readlong f)
																	)

																fseek f (SectionSize + StartPos) #seek_set
														)
													0x1009:
														(
																if LoadMats and LoadCurrentMesh then
																(
																		NumSurfaces = readshort f --; format " EMESH_CHUNK_SFACE [%]\n" NumSurfaces
																		Result[2][MeshIndex+1] = #()
																		
																		for i = 1 to NumSurfaces do
																		(
																				UnkStr1 = readstring f --; format "\tMat name = %\n" UnkStr1 
																				append Result[2][MeshIndex+1] UnkStr1
																				SNumFaces = readlong f #unsigned --; format "\tnum faces = %\n" SNumFaces
																				for j = 1 to SNumFaces do setFaceMatID m ((readlong f #unsigned) + 1) i
																		)
																)
																
																fseek f (SectionSize + StartPos) #seek_set
														)
													0x1012:
														(
															if LoadMats and LoadCurrentMesh then
															(
																NumTextureTables = readlong f --; format " EMESH_CHUNK_VMAPS_2 [%]\n" NumTextureTables 
														
																VTable = #() -- vert values table
																ITable = #() -- indexes value tables
																VTable2 = #() -- additional map verts indexes
																BoneNamesList = #() -- bone names table list
																TabIndex = 1
																
																for i = 1 to NumTextureTables do
																(
																		UnkStr2 = readstring f --; format "\n\t\t(%)Table name = %\n" (i-1) UnkStr2
																		TableType = readbyte f --; format "\t\tTable Type = %\n" TableType 
																		TableID = readshort f --; format "\t\tTableID = %\n" TableID
																		NumTVerts = readlong f --; format "\t\tNumTVerts = %\n" NumTVerts
																		--fseek f (NumTVerts*8) #seek_cur ; format "\t\t.... uv skiping NumTVerts*float[2] to %\n" (ftell f)
																		
																		case TableType of
																		(
																			2: -- Texture
																				(
																					VTable[i] = #()
																					
																					for j = 1 to NumTVerts do
																					(
																							u = readfloat f ; v = readfloat f
																							append VTable[i] [ u , 1 - v , 0]
																					)
																					
																					ITable[i] = for j = 1 to NumTVerts collect (readlong f #unsigned)
																					
																					if TableID == 1 then (VTable2 = for j = 1 to NumTVerts collect (readlong f #unsigned) ; TexTabID2 = i)
																					else TexTabID1 = i
																				)
																				
																			1: -- bone
																				(
																						VTable[i] = #()
																						BoneNamesList[i] = UnkStr2
																						
																						for j = 1 to NumTVerts*2 do
																						(
																								u = readfloat f
																								append VTable[i] u
																								--format "\t\t\t%, %\n" (j-1) u
																						)
																				)
																				
																			default:( break() )
																		) -- case TableType 
																)
																
																
																meshop.setNumMaps m 1
																meshop.setMapSupport m 1 true
																meshop.defaultMapFaces m 1
																meshop.setNumMapVerts m 1 NumVMREFS --(NumFaces*3) keep:true -- tfmas
																
																MaxValue = VTable[TexTabID1].count
																
																for i = 1 to NumFaces do
																(
																		meshop.setmapface m 1 i tfmas[i]
																		--for k = 1 to 3 do 
																			--if fmas[i][k] <= MaxValue then
																				--meshop.setMapVert m 1 tfmas[i][k] VTable[TexTabID1][fmas[i][k]]
																)
																
																for i = 1 to NumVMREFS do
																(
																		j = XTable[i][1][1] + 1
																		k = XTable[i][1][2] + 1
																		v = VTable[j][k]
																		meshop.setMapVert m 1 i v
																)
																
															)
															
															fseek f (SectionSize + StartPos) #seek_set
														)
													default:
														(
																fseek f SectionSize #seek_cur
																--format ".... skiped\n"
														)
												) -- case mesh
												
										) -- while loading mesh
										
										fseek f CurMeshSize #seek_set

										--format "...MESH % LOADED\n" MeshIndex 
								)
						) ------

					0x0907:
						(
								NUM_MATERIALS = readlong f --; format "\tNUM_MATERIALS = %\n" NUM_MATERIALS
								
								if LoadMats and LoadCurrentMesh then
								(
										local MatList = #()
										local MatNameList = #()
										
										for i = 1 to NUM_MATERIALS do
										(
												MaterialName = readstring f --; format "\t\tmaterial %: %\n" (i-1) MaterialName
												MatNameList[i] = MaterialName
												EngineMaterial = readstring f --; format "\t\t\tEngineMaterial: %\n" EngineMaterial
												CompileMaterial = readstring f --; format "\t\t\tCompileMaterial: %\n" CompileMaterial
												GameMaterial = readstring f --; format "\t\t\tGameMaterial: %\n" GameMaterial
												FileNameMaterial = readstring f --; format "\t\t\tFileNameMaterial: %\n" FileNameMaterial
												unkMatStr = readstring f --; format "\t\t\tunkMatStr: %\n" unkMatStr
												MaterialDoubleSide = readlong f --; format "\t\t\tDouble side : %\n" MaterialDoubleSide 
												MaterialUnkLong1 = readlong f --; format "\t\t\tMaterialUnkLong1 : 0x%\n" (bit.intashex MaterialUnkLong1)
												MaterialUnkLong2 = readlong f --; format "\t\t\tMaterialUnkLong2 : 0x%\n" (bit.intashex MaterialUnkLong2)
												
												chema = xray_check_scene_materials (TexPath + "\\" + FileNameMaterial + ".dds") EngineMaterial CompileMaterial GameMaterial MaterialDoubleSide
												
												if chema == undefined then
												(
														if 	(EngineMaterial == "def_shaders\\def_trans_v") or 
															(EngineMaterial == "def_shaders\\def_aref") or
															(EngineMaterial == "def_shaders\\def_aref_v") or
															(EngineMaterial == "def_shaders\\def_trans") or
															(EngineMaterial == "def_shaders\\def_trans_v_tuchi") or
															(EngineMaterial == "flora\\leaf_wave") then isOpacity = true
														else isOpacity = false
														
														if (S_T_A_L_K_E_R_Mtl != undefined) then
														(
																MatList[i] = S_T_A_L_K_E_R_Mtl name:MaterialName
																MatList[i].EShaderByName = EngineMaterial
																MatList[i].CShaderByName = CompileMaterial
																MatList[i].GameMtlByName = GameMaterial
														)
														else
																MatList[i] = standard name:MaterialName
																
														if MaterialDoubleSide != 0 then MatList[i].twoSided = true
														MatList[i].DiffuseMap = bitmaptexture filename:(TexPath + "\\" + FileNameMaterial + ".dds")
														MatList[i].DiffuseMap.monoOutput = 0
														MatList[i].DiffuseMap.RGBOutput = 0
														MatList[i].DiffuseMap.alphasource = 2
														
														if isOpacity then
														(
																MatList[i].opacityMap = copy MatList[i].DiffuseMap
																MatList[i].opacityMap.monoOutput = 1
																MatList[i].opacityMap.RGBOutput = 1
																MatList[i].opacityMap.alphasource = 0
														)
														
														showTextureMap MatList[i] true
												)
												else MatList[i] = chema
										)
										
										for i = 1 to Result[1].count where Result[1][i]!=undefined do 
										(
												m = Result[1][i]
												names = Result[2][i]
												CurMat = multimaterial numsubs:names.count --name:(filenamefrompath fname)
												
												for j = 1 to names.count do
												(
														ind = findItem MatNameList names[j]
														if ind == 0 then format "############################################## cant find material %\n" names[j]
														else
														(
																CurMat[j] = MatList[ind]
														)
												)
												
												m.material = CurMat
										)
								)
								
								fseek f (SectionSize + StartPos) #seek_set
						)
					0x921:
						(
								fseek f (SectionSize + StartPos) #seek_set
						)
						
					default:
						(
								fseek f SectionSize #seek_cur
								--format ".... skiped\n"
						)
				) -- case
		) -- while

		return Result
		
) -- fn






