if xrayUtilites != undefined then
(
	rollout dummyrollout "" ( )
	addRollout dummyrollout
	removeRollout dummyrollout
	closeUtility xrayUtilites
)

utility xrayUtilites "x-ray tools"
(
	button ImpObjBtn "Import object" width:120
	button ExpObjBtn "Export object" width:120
	button LoadSklsBtn "Load motion" width:120
	button ExportMotionBtn "Export motion" width:120
	button AnmIOBtn "*.anm i/o" width:120
	
	on ImpObjBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrTools.ObjectImport.ms") quiet:true) 
		catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrTools.ObjectImport.ms"))
	on ExpObjBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrTools.ObjectExport.ms") quiet:true) 
		catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrTools.ObjectExport.ms"))
	on LoadSklsBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrTools.LoadMotion.ms") quiet:true) 
		catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrTools.LoadMotion.ms"))
	on ExportMotionBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrTools.ExportMotion.ms") quiet:true) 
		catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrTools.ExportMotion.ms"))
	on AnmIOBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrTools.anm_io.ms") quiet:true) 
		catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrTools.anm_io.ms"))
			
	
	group "material helper"
	(
		button SetStalkerMtl "Add shaders def" width:120 align:#center
		radiobuttons SetStalkerMtlType labels:#("med","obj","all") columns:3 align:#center
	)
	
	on SetStalkerMtl pressed do
		if xrShadersDataCA == undefined then messagebox "Reinstall 'x-ray tools' to use this option"
		else
		(
			case SetStalkerMtlType.state of
			(
				1: 	(	
						Mtl = medit.getcurmtl()
						if classof Mtl != Multimaterial then Mtl = #(Mtl)
						for m in Mtl where classof m == Standardmaterial do
							if not (xrToolsUtil.HasShadersCA m) then custAttributes.add m xrShadersDataCA
					)
				2: 	(	
						for obj in selection where obj.material != undefined do
						(
							Mtl = obj.material
							if classof Mtl != Multimaterial then Mtl = #(Mtl)
							for m in Mtl where classof m == Standardmaterial do
								if not (xrToolsUtil.HasShadersCA m) then custAttributes.add m xrShadersDataCA
						)
					)
				3: 	(	
						for Mtl in scenematerials do
						(
							if classof Mtl != Multimaterial then Mtl = #(Mtl)
							for m in Mtl where classof m == Standardmaterial do
								if not (xrToolsUtil.HasShadersCA m) then custAttributes.add m xrShadersDataCA
						)
					)
			)
		)
	
	
	group "utils"
	(
		--button ShowLinksBtn "show links" width:120 align:#center
		button ForestBtn "forest generator" width:120 align:#center
		--button WpnHelperBtn "wpn hud helper" width:120 align:#center
		button BoneScalerBtn "scaler tool" width:120 align:#center tooltip:"scale collision files (*.bones), scale animation position keys (*.skl/*skls)"
		button SimpleFenceBtn "simple fence" width:120 align:#center
		button EditOmfBtn "OMF editor" width:120 align:#center
		button RagDollBtn "ragdoll helper" width:120 align:#center
		--button AttachWeaponBtn "attach weapon" width:120 align:#center
		button RunningMobBtn "running mob :)" width:120 align:#center
	)
	
	--on ShowLinksBtn pressed do
		--for obj in selection do obj.showlinks = true
	on ForestBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\ForestGenerator.ms") quiet:true) 
		catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\ForestGenerator.ms"))	
	
	on BoneScalerBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrTools.BoneScaler.ms") quiet:true) 
		catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrTools.BoneScaler.ms"))

	on SimpleFenceBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrTools.SimpleFence.ms") quiet:true) 
		catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrTools.SimpleFence.ms"))
			
	on EditOmfBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrayTools.EditOmf.ms") quiet:true) 
		catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrayTools.EditOmf.ms"))
			
	on RagDollBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrayTools.RagDollValuesHelper.ms") quiet:true) 
		catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrayTools.RagDollValuesHelper.ms"))
			
	--on WpnHelperBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrTools.wpn_hud_helper.ms") quiet:true) 
		--catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrTools.wpn_hud_helper.ms"))
			
	--on AttachWeaponBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrTools.attach_weapon.ms") quiet:true) 
		--catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrTools.attach_weapon.ms"))
			
	on RunningMobBtn pressed do try ( fileIn (scriptspath+"\\xray_tools\\xrTools.running_mob.ms") quiet:true) 
		catch (messagebox("file not founded " + scriptspath+"\\xray_tools\\xrTools.running_mob.ms"))
	
	
	--label txt_00 "-------------------------------" offset:[0,12]
	--label txt_01 "by Den-Stash"
	--label txt_02 "-------------------------------"
)

openUtility xrayUtilites 