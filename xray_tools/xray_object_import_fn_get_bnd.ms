

fn GetObjectBounds f filesize = 
(
		sectionId = readlong f ; if sectionId != 0x7777 then ( format "\n### Unsupported file version\n" ; return #() )
		SectionSize = readlong f #unsigned

		fn ReadPoint f = 
		(
			local x = readfloat f
			local z = readfloat f
			local y = readfloat f
			return [x, y, z]
		)
		
		local vmas = #(), fmas = #(), tvmas = #(), tfmas = #(), BugReport = #()
		local TexPath = "C:\\Program Files\\X-Ray CoP SDK\\editors\\gamedata\\textures" --TPathTxt.text --TexturePath
		local SectionEndOfs, Result = #()
		local TexTabID1, TexTabID2
		local EOBJ_CHUNK_FLAGS, EOBJ_CHUNK_VERSION, EOBJ_CHUNK_USERDATA, EOBJ_CHUNK_LOD_REF
		local VTable, ITable, VTable2 , BoneNamesList, XTable = #()
		
		while true do
		(
				CurPos = ftell f
				if CurPos >= filesize then exit
				sectionId = readlong f ; if sectionId == undefined then ( format "\n# eof\n" ; exit )
				SectionSize = readlong f #unsigned
				StartPos = ftell f
				SectionEndOfs = StartPos + SectionSize
				if SectionEndOfs > filesize then (format "\n### NOT EXPECTED END\n" ; exit )
				
				case sectionId of
				(
					0x7777: ()
					0x0900:
						(
								EOBJ_CHUNK_VERSION = readshort f
								if EOBJ_CHUNK_VERSION != 16 then ( format "\n### Unsupported file version\n" ; return #() )
						)
					0x0925:
						(
								EOBJ_CHUNK_LOD_REF = readstring f
								fseek f SectionEndOfs #seek_set
						)
					0x0903:
						(
								EOBJ_CHUNK_FLAGS = readlong f
						)
					0x0910:
						(
								MeshesEndOfs = SectionSize + (ftell f)
								Result[1] = #()
								Result[2] = #()
																
								while true do
								(
										if (ftell f) >= MeshesEndOfs then exit
										MeshIndex = readlong f
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
														)
													0x1001:
														(
																EMESH_CHUNK_MESHNAME = readstring f
														)
													0x1004:
														(
																Result[1] = for i = 1 to 6 collect (readfloat f)
														)
													0x1002:
														(
																EMESH_CHUNK_FLAGS = readbyte f
																Result[2] = EMESH_CHUNK_FLAGS
																return Result
														)
													default:
														(
																fseek f SectionSize #seek_cur
														)
												) -- case mesh
												
										) -- while loading mesh
										
										fseek f CurMeshSize #seek_set
								)
						)
					0x921:
						(
								fseek f (SectionSize + StartPos) #seek_set
						)
						
					default:
						(
								fseek f SectionSize #seek_cur
						)
				) -- case
		) -- while

		return Result
		
) -- fn






