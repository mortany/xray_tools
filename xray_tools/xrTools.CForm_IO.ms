rollout xray_collision_rol "x-ray collision CFORM"
(
	button LoadCol "Import" width:120
	button SaveCol "Export" width:120
	
	button LoadMats "Load mtl" width:120
	
local MatData = #(#(),#())
	
fn ReadPoint f = 
(
	local x = readfloat f
	local z = readfloat f
	local y = readfloat f
	return [x, y, z]
)

fn writepoint f p =
(
	writefloat f p.x
	writefloat f p.z
	writefloat f p.y
)

fn IntToString A n =
(
	local i , str = A as string
	local m = n - str.count
	for i = 1 to m do str = "0" + str
	str
)

struct cop_section 
(
	ID, Size = -1, 
	fn read f =
	(
		ID = readlong f
		Size = readlong f
	)
)

fn LoadMaterials f =
(
	local Section = cop_section ()
	local res = #(#(),#())
	
	
	while true do
	(
		Section.read f
		if Section.ID == undefined then ( format "\n#eof\n" ; return undefined )
		SectionEndOfs = (ftell f) + Section.Size
		format "Section ID = 0x% (%) , size = % , (at %) " (bit.intashex Section.ID) Section.ID Section.Size (ftell f)
		
		case Section.ID of
		(
		4098:
			(
				format " | try to read\n"
				
				while true do
				(
						if (ftell f) >= SectionEndOfs then exit
						Section.read f
						CurEndOfs = (ftell f) + Section.Size
						readlong f
						readlong f
						id2 = readlong f
						SName = readstring f
						format "\t[%]\t%\t%\n" (IntToString Section.ID 4) id2 Sname
						fseek f CurEndOfs #seek_set
						append res[1] id2
						append res[2] Sname
				)

				fseek f SectionEndOfs #seek_set
			)
		default:
			(
					format " | ......... skiped\n"
					fseek f Section.Size #seek_cur
			)
		) -- case
	)
	
	return res
) -- fn

fn LoadCForm f =
(
	local Ver = readlong f
	
	local NumVerts = readlong f
	local NumFaces = readlong f
	format "Version = %, Verts = %, faces = %\n" Ver NumVerts NumFaces
	
	local BMin = ReadPoint f
	local BMax = ReadPoint f
	format "min = %, max = %\n" bmin bmax
	
	vertArray = for i = 1 to NumVerts collect ReadPoint f
	faceArray = #()
	sectA = #()
	flagsA = #()
	sfaces = #()
	matids = #()
	matidlist = #()
	
	for i = 1 to NumFaces do
	(
		ind = [readlong f,readlong f,readlong f]
		flags = readshort f #unsigned
		matid = (bit.and flags 16383) + 1
		matidlist[matid] = matid
		sector = (readshort f) + 1
		if sfaces[sector] == undefined then sfaces[sector] = #{}
		append sfaces[sector] i
		append faceArray [ind.x + 1, ind.z + 1, ind.y + 1]
		append matids matid
	)
	
	minus = 0
	for i = 1 to matidlist.count do 
		if matidlist[i] == undefined then minus += 1
		else matidlist[i] -= minus
		
	--print matidlist
		
	mat = multimaterial name:"cform" numsubs:(matidlist.count - minus)
	for i = 1 to mat.numsubs do mat[i] = standard diffuse:(random (color 50 50 50) (color 200 200 200))
	
	m = mesh vertices:vertarray faces:facearray
	m.material = mat
	
	for i = 1 to NumFaces do
	(
		setFaceSmoothGroup m i 0
		setFaceMatID m i matidlist[matids[i]]
	)
	
	
)

fn ExportCForm f =
(
	sob = snapshot selection[1]
	writelong f 4
	
	writelong f sob.numverts
	writelong f sob.numfaces
	
	writepoint f sob.min
	writepoint f sob.max

	for i = 1 to sob.numverts do writepoint f (getvert sob i)
	
	for i = 1 to sob.numfaces do
	(
		ind = (getface sob i) - [1,1,1]
		writelong f ind[1] ; writelong f ind[3]; writelong f ind[2]
		flags = getfacesmoothgroup sob i
		sector = (getfacematid sob i) - 1
		
		writeshort f flags
		writeshort f sector
	)
	
	delete sob
)

on LoadMats pressed do
(
	bob = selection[1]
	
)

on LoadCol pressed do
(
	clearlistener()
	fname = getopenfilename types:"xray collision *.cform|*.cform"
	T = timestamp()

	if fname != undefined then
	(
		f = fopen fname "rb"
		if f!=undefined then LoadCForm f
		fclose f
	)

	format "%s\n" ((timestamp() - T)/1000.)
)

on SaveCol pressed do
	if selection.count != 1 then messagebox "select just one object to export"
	else
		if superclassof selection[1] != geometryclass then messagebox "selected is not geometry"
		else
		(
			-- export
			clearlistener()
			fname = getsavefilename types:"xray collision *.cform|*.cform"
			T = timestamp()

			if fname != undefined then
			(
				f = fopen fname "wb"
				if f!=undefined then ExportCForm f 
					else messagebox "cant save file"
				fclose f
			)

			format "%s\n" ((timestamp() - T)/1000.)
		)

)
try (closeRolloutFloater xray_collision_flo) catch ()
xray_collision_flo = newRolloutFloater "x-ray tools" 160 200 40 130
addRollout  xray_collision_rol xray_collision_flo