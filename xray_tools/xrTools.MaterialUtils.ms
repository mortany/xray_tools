rollout xr_scaler_rol "x-ray material utils by SkyLoader"
(
group "fixers"
(
	button BFFixMatIDsBtn "Fix material IDs" width:170
)

on BFFixMatIDsBtn pressed do
(
		for obj in selection where (obj.material != undefined and (classof obj == Editable_mesh or classof obj == Editable_Poly)) do
		(
			local Mtl = obj.material
			if classof Mtl != Multimaterial then Mtl = #(Mtl)

			ts = timestamp ()
			format "start optimizing materials\n"

			local i, MatID

			for i = 1 to (getNumFaces obj) do
			(
				if classof obj == Editable_mesh then
					MatID = getFaceMatID obj i
				else
					MatID = polyop.getfacematID obj i
				while MatID > Mtl.count do
				(
					MatID -= Mtl.count
				)
				if classof obj == Editable_mesh then
					setfacematID obj i MatID
				else
					polyop.setfacematID obj i MatID
			)
			format "done at % sec\n" ((timestamp() - ts)/1000.)
		)
)

group "combine materials"
(
	checkbox CBIgnoreShaders "ignore different shaders" checked:true
	checkbox CBIgnoreComShaders "ignore different compile shaders" checked:true
	checkbox CBIgnoreMtls "ignore different mtl-s" checked:true
	checkbox CBIgnore2Sided "ignore different 2-sided flag"
	button BFCombineMatBtn "Combine identical materials" width:170
)

on BFCombineMatBtn pressed do
(

	for obj in selection where (obj.material != undefined and (classof obj == Editable_mesh or classof obj == Editable_Poly)) do
	(
		Mtl = obj.material
		if classof Mtl != Multimaterial then Mtl = #(Mtl)
		local i, j, k

		ts = timestamp ()
		format "start combining materials\n"

		for i = 1 to Mtl.count do
		(
			if classof Mtl[i] == Standardmaterial and classof Mtl[i].diffuseMap == Bitmaptexture then
			(
				j = i+1
				while (j<=Mtl.count) do
				(
					if classof Mtl[j] == Standardmaterial and classof Mtl[j].diffuseMap == Bitmaptexture then
					(
						if (stricmp Mtl[i].diffuseMap.filename Mtl[j].diffuseMap.filename == 0) and xrToolsUtil.CheckIgnoreShaders Mtl[i] Mtl[j] CBIgnore2Sided.checked CBIgnoreShaders.checked CBIgnoreComShaders.checked CBIgnoreMtls.checked then
						(
								Mtl[j] = nil

								for k = j+1 to Mtl.count do
									Mtl[k-1] = Mtl[k]

								for k = 1 to (getNumFaces obj) do
								(
									if classof obj == Editable_mesh then
									(
										local id = (getFaceMatID obj k) - 1
										if (id+1 == j) then
											setfacematID obj k i
										else if (id+1 > j) then
											setfacematID obj k id
									) else (
										local id = (polyop.getfacematID obj k) - 1
										if (id+1 == j) then
											polyop.setfacematID obj k i
										else if (id+1 > j) then
											polyop.setfacematID obj k id
									)
								)

								Mtl.count -= 1
								continue
						)
					)
					j += 1
				)
			)
		)
		format "done at % sec\n" ((timestamp() - ts)/1000.)
	)
)


group "global renaming"
(
	radiobuttons RBRenameSelectedType labels:#("material editor","selected obj") columns:2 align:#center
	button BFGlobalRenameBtn "Run global renaming textures" width:170
)

on BFGlobalRenameBtn pressed do
(
	local textures_path = GetINISetting (scriptsPath + "xr_scripts_settings.txt") "paths" "last_textures_path"
	local textures_path_cnt = textures_path.count + 2

	if textures_path != "" then
	(
		case RBRenameSelectedType.state of
		(
			1: 	(
					Mtl = medit.getcurmtl()
					if classof Mtl != Multimaterial then Mtl = #(Mtl)
					for m in Mtl where classof m == Standardmaterial and classof m.diffuseMap == Bitmaptexture do
					(
						local filename_without_dds = m.diffuseMap.filename.count - textures_path_cnt - 3 --/sub path and '.dds'
						local final_name = substring m.diffuseMap.filename textures_path_cnt filename_without_dds
						local new_name = getINISetting (scriptsPath + "xray_tools\\xrtools.renametextureslist.txt") "rename_textures_list" final_name
						if (new_name != "") then
						(
							new_name = textures_path + "\\" + new_name + ".dds"
							--format "Exist % \n" new_name

							m.diffuseMap.filename = new_name
						)
						else
						(
							--format "Not Exist %\n" final_name
						)
					)
				)
			2: 	(
					for obj in selection where obj.material != undefined do
					(
						local Mtl = obj.material
						if classof Mtl != Multimaterial then Mtl = #(Mtl)
						for m in Mtl where classof m == Standardmaterial and classof m.diffuseMap == Bitmaptexture do
						(
							local filename_without_dds = m.diffuseMap.filename.count - textures_path_cnt - 3 --/sub path and '.dds'
							local final_name = substring m.diffuseMap.filename textures_path_cnt filename_without_dds
							local new_name = getINISetting (scriptsPath + "xray_tools\\xrtools.renametextureslist.txt") "rename_textures_list" final_name
							if (new_name != "") then
							(
								new_name = textures_path + "\\" + new_name + ".dds"
								--format "Exist % \n" new_name

								m.diffuseMap.filename = new_name
							)
							else
							(
								--format "Not Exist %\n" final_name
							)
						)
					)
				)
		)
	)
)

) -- roll

try (closeRolloutFloater xr_scaler_flo) catch ()
xr_scaler_flo = newRolloutFloater "x-ray utils" 240 295 40 130
addRollout  xr_scaler_rol xr_scaler_flo


