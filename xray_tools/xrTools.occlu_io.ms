rollout xray_occluders_rol "x-ray occluders"
(
	group "HOM" (
		button ImportHOM "Import" width:100
		button ExportHOM "Export" width:100
	)

	group "SOM" (
		button ImportSOM "Import" width:100
		button ExportSOM "Export" width:100
	)
	
	
fn writepoint f p =
(
	writefloat f p.x
	writefloat f p.z
	writefloat f p.y
)

fn read_hom f =
(
	local h = readlong f, s = readlong f
	if h != 0 or s != 4 then (format "unsupported header\n"; return undefined)
	readlong f
	
	h = readlong f; if h != 1 then (format "unsupported file format\n"; return undefined)
	local BlockSize = (readlong f) + 20
	
	local va = #() , fa = #(), cnt = 1, mid = #()
	
	while true do
	(
		if (ftell f) >= BlockSize then exit
		p = for i = 1 to 9 collect readfloat f
		append mid (readlong f)
		
		j = 3*fa.count
		
		append va [p[1],p[3],p[2]]
		append va [p[4],p[6],p[5]]
		append va [p[7],p[9],p[8]]
		append fa [j+1, j+3, j+2]
	)
	
	m = undefined
	
	if fa.count > 0 then 
	(
		m = mesh vertices:va faces:fa name:"hom"
		for i = 1 to m.numfaces do setFaceMatID m i (mid[i]+1)
	)
	
	return m
)

fn write_hom f =
(
	local objs = for obj in selection where superclassof obj == GeometryClass collect (snapshot obj)
	if objs.count == 0 then return false
	local bob = objs[1]
	for i = 2 to objs.count do attach bob objs[i]
	
	writelong f 0
	writelong f 4
	writelong f 0
	writelong f 1
	writelong f (bob.numfaces*40)
	
	for i = 1 to bob.numfaces do
	(
		v = getface bob i
		WritePoint f (getvert bob v[1])
		WritePoint f (getvert bob v[3])
		WritePoint f (getvert bob v[2])
		ds = if getFaceMatID bob i == 1 then 0 else 1
		writelong f ds
	)
	
	delete bob
)

fn read_som f =
(
	local h = readlong f, s = readlong f
	if h != 0 or s != 4 then (format "unsupported header\n"; return undefined)
	readlong f
	
	h = readlong f; if h != 1 then (format "unsupported file format\n"; return undefined)
	local BlockSize = (readlong f) + 20
	
	local va = #() , fa = #(), cnt = 1, vol = #(), mid = #()
	
	while true do
	(
		if (ftell f) >= BlockSize then exit
		p = for i = 1 to 9 collect readfloat f
		append mid ((readlong f) + 1)
		append vol (readfloat f)
		
		j = 3*fa.count
		
		append va [p[1],p[3],p[2]]
		append va [p[4],p[6],p[5]]
		append va [p[7],p[9],p[8]]
		append fa [j+1, j+3, j+2]
		--cnt += 1; format "%: %\n" cnt fa[i+1][j+1]
	)
	
	m = undefined
	
	if fa.count > 0 then 
	(
		m = mesh vertices:va faces:fa name:"som"
		
		for i = 1 to m.numfaces do 
		(
			setFaceMatID m i mid[i]
			j = getface m i
			for k = 1 to 3 do meshop.setVertAlpha m -2 j[k] (vol[i])
		)
	)
	
	return m
)

fn write_som f =
(
	local objs = for obj in selection where superclassof obj == GeometryClass collect (snapshot obj)
	if objs.count == 0 then return false
	local bob = objs[1]
	for i = 2 to objs.count do attach bob objs[i]
	
	writelong f 0
	writelong f 4
	writelong f 0
	writelong f 1
	writelong f (bob.numfaces*44)
	
	HasVCol = meshop.getmapsupport bob -2 ; format "VA support = %\n" HasVCol
	
	for i = 1 to bob.numfaces do
	(
		v = getface bob i
		WritePoint f (getvert bob v[1])
		WritePoint f (getvert bob v[3])
		WritePoint f (getvert bob v[2])
		ds = if getFaceMatID bob i == 1 then 0 else 1
		writelong f ds
		if HasVCol then
		(
			cv = meshop.getmapface bob -2 i
			a = ((meshop.getmapvert bob -2 cv[1]) + (meshop.getmapvert bob -2 cv[2]) + (meshop.getmapvert bob -2 cv[3]))/3.
			writefloat f a.x
			format "face % = %\n" i a
		)
		else writefloat f 0.0
	)
	
	delete bob
)


on ImportHOM pressed do
(
	fname = getopenfilename types:"occluders|*.hom|"

	if fname != undefined then
	(
		f = fopen fname "rb"
		if f == undefined then messagebox "cant open file"
		else
		(
			clearlistener()
			read_hom f
			fclose f
		)
	)
)

on ExportHOM pressed do
(
	fname = getsavefilename types:"occluders|*.hom|"

	if fname != undefined then
	(
		f = fopen fname "wb"
		if f == undefined then messagebox "cant create file"
		else
		(
			clearlistener()
			write_hom f
			fclose f
		)
	)
)

on ImportSOM pressed do
(
	fname = getopenfilename types:"sound occluders|*.som|"

	if fname != undefined then
	(
		f = fopen fname "rb"
		if f == undefined then messagebox "cant open file"
		else
		(
			clearlistener()
			read_som f
			fclose f
		)
	)
)

on ExportSOM pressed do
(
	fname = getsavefilename types:"sound occluders|*.som|"

	if fname != undefined then
	(
		f = fopen fname "wb"
		if f == undefined then messagebox "cant create file"
		else
		(
			clearlistener()
			write_som f
			fclose f
		)
	)
)

)
try (closeRolloutFloater xray_occluders_flo) catch ()
xray_occluders_flo = newRolloutFloater "x-ray tools" 140 200 40 130
addRollout  xray_occluders_rol xray_occluders_flo