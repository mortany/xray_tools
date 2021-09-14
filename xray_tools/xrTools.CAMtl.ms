
global xrShadersDataCA
global xrShaderTypeChoosen
global xrShadersList
global xrImportFilesList
global xrImportFilesPath

xrShadersDataCA = attributes xrShadersData
(
	parameters main rollout:params
	(
		EShader type:#string ui:EShader default:"default"
		CShader type:#string ui:CShader default:"default"
		GameMaterial type:#string ui:GameMaterial default:"default"
	)
	
	rollout params "xray shader params"
	(
		edittext EShader across:2 width:180 align:#left
		button EShaderGet "Engine shader" width:100 align:#right
		edittext CShader across:2 width:180 align:#left
		button CShaderGet "Compile shader" width:100 align:#right
		edittext GameMaterial across:2 width:180 align:#left
		button GameMtlGet "Game material" width:100 align:#right
		
		on EShaderGet pressed do
		(
			xrShaderTypeChoosen = 1
			--format "test: %\n" (custAttributes.getOwner this)
			try ( filein (scriptsPath + "xray_tools\\xrtools.shaderSelector.ms") ) catch (messagebox "Install x-ray tools in order to use this option")
		)
		on CShaderGet pressed do
		(
			xrShaderTypeChoosen = 2
			try ( filein (scriptsPath + "xray_tools\\xrtools.shaderSelector.ms") ) catch (messagebox "Install x-ray tools in order to use this option")
		)
		on GameMtlGet pressed do
		(
			xrShaderTypeChoosen = 3
			try ( filein (scriptsPath + "xray_tools\\xrtools.shaderSelector.ms") ) catch (messagebox "Install x-ray tools in order to use this option")
		)
	)
)