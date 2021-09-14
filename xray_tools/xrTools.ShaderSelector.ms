if GUI_ShaderChanger != undefined then
(
	try (destroyDialog GUI_ShaderChanger) catch()
)

rollout GUI_ShaderChanger "shader selector"
(
	radiobuttons SType labels:#("Engine","Compile","Game Mtl") columns:3
	listBox lbShaders "" width:240 height:36 enabled:true
	button btnAssign "ASSIGN" width:100 across:2
	button btnClose "CLOSE" width:100
	
	/*
	group "presets"
	(
		dropdownlist PresetList items:#() across:2 align:#left width:180
		button DeletePreset "delete" width:40 align:#right
		edittext preset_text across:2 align:#left width:180
		button CreatePreset "create" width:40 align:#right
	)
	*/
	
	fn SetShader type value =
	(
		local m = medit.getcurmtl()
		
		case type of
		(
			1: 	m.EShader = value
			2: 	m.CShader = value
			3: 	m.GameMaterial = value
		)
	)
	
	fn RefreshList type = 
	(
		lbShaders.items = xrShadersList[type]
	)
	
	
	
	on GUI_ShaderChanger open do
	(
		if xrShaderTypeChoosen == undefined then xrShaderTypeChoosen = 1
		if xrShadersList == undefined then
		(
			xrShadersList = #()
			xrShadersList[1] = getINISetting (scriptsPath + "xray_tools\\xrtools.shaderlist.txt") "E_Shader_List"
			xrShadersList[2] = getINISetting (scriptsPath + "xray_tools\\xrtools.shaderlist.txt") "C_Shader_List"
			xrShadersList[3] = getINISetting (scriptsPath + "xray_tools\\xrtools.shaderlist.txt") "G_Mtl_List"
		)
		RefreshList xrShaderTypeChoosen
		SType.state = xrShaderTypeChoosen
	)
	
	on SType changed st do
	(
		xrShaderTypeChoosen = st
		RefreshList st
	)
	
	on lbShaders doubleClicked i do
	(
		SetShader xrShaderTypeChoosen lbShaders.items[i]
		--destroyDialog GUI_ShaderChanger
	)
	
	on btnAssign pressed do
	(
		SetShader xrShaderTypeChoosen lbShaders.selected
	)
	
	on btnClose pressed do 
	(
		destroyDialog GUI_ShaderChanger
	)
)

createDialog GUI_ShaderChanger pos:[500,80] width:265 height:GUI_ShaderChanger.height modal:true \
								style:#(#style_titlebar, #style_sysmenu, #style_resizing, #style_border)
