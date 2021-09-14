rollout xr_scaler_rol "x-ray scaler tool"
(
label lbl_0 "scale" align:#left across:2
spinner scaleSize range:[0,100000,1] scale:.001 width:60 align:#right
group "bones"
(
	button resizeBones "resize bones" width:140
	checkbox reverseJoint "reverse ragdoll angles"
)

group "motion"
(
	button resizeAnim "resize animation" width:140
)

struct cop_section 
(
	ID, Size = -1, 
	fn read f =
	(
		ID = readlong f
		Size = readlong f
	),
	fn write fo =
	(
		writelong fo ID
		writelong fo Size
	),
	fn copy f fo =
	(
		local i
		if Size != undefined then
			for i = 1 to Size do writebyte fo (readbyte f)
	)
)

fn ReadPoint f = 
(
	local x = readfloat f
	local z = readfloat f
	local y = readfloat f
	return [x, y, z]
)

fn CopyData f1 f2 N =
(
		local i
		for i = 1 to N do writebyte f2 (readbyte f1)
)

---------------------------------------------------------------------------------------------------------------------------------------------
fn read_bone_file f fo new_scale =
(
	local Section = cop_section ()
	local n = 0
	
	while true do
	(				
		Section.read f ; if Section.ID == undefined or Section.size == undefined then ( format "\n#eof\n" ; return undefined )
		Section.write fo
		if Section.ID > 500 then (Section.copy f fo ; exit)
		EndOfs = Section.size + (ftell f)
		format "* bone data [%]\n" Section.ID
				
		while true do
		(
			if ftell f >= EndOfs then exit
			Section.read f ; if Section.ID == undefined or Section.size == undefined then ( format "\n#eof\n" ; return undefined )
			Section.write fo
			format "\t| section [%] size [%] " Section.ID Section.size
			
			case Section.ID of
			(
					0x5: --
					(
							format " | -- transform\n"
							shape_type = readshort f ; writeshort fo shape_type
							shape_flags = readshort f ; writeshort fo shape_flags
							for i = 1 to 9 do writefloat fo ((readfloat f)*1) -- matrix3
							for i = 1 to 6 do writefloat fo ((readfloat f)*new_scale)
							for i = 1 to 4 do writefloat fo ((readfloat f)*new_scale)
							for i = 1 to 8 do writefloat fo ((readfloat f)*new_scale)
					)
					0x6:
					(
							joint_type = readlong f ; writelong fo joint_type ; format " | joint_type = %\n" joint_type
							
							AxisMin = [0,0,0]; AxisMax = [0,0,0]; SprFactor = [0,0,0]; DumpFactor = [0,0,0]
							
							for i = 1 to 3 do
							(
									AxisMin[i] = readfloat f
									AxisMax[i] = readfloat f
									SprFactor[i] = readfloat f
									DumpFactor[i] = readfloat f
									
									if reverseJoint.checked then
									(
										writefloat fo (-AxisMax[i])
										writefloat fo (-AxisMin[i])
									)
									else
									(
										writefloat fo AxisMin[i]
										writefloat fo AxisMax[i]
									)
									writefloat fo SprFactor[i]
									writefloat fo DumpFactor[i]
							)
							
							SpringFactor = readfloat f ; writefloat fo SpringFactor 
							DumpingFactor = readfloat f ; writefloat fo DumpingFactor
					)
				default:
					(
							format " | ......... copy\n"
							Section.copy f fo
					)
			) -- case
		) -- while
	) -- while
		
) -- fn


---------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------- BONES
---------------------------------------------------------------------------------------------------------------------------------------------
on resizeBones pressed do
(
		EditorPath = getinisetting (scriptsPath + "xr_scripts_settings.txt") "paths" "editorpath"
		if EditorPath == "" then EditorPath = "C:\\Program Files\\X-Ray CoP SDK\\editors"
		fname = getopenfilename types:"bones|*.bones" filename:(EditorPath  + "\\import\\*.bones")
		
		if fname != undefined then
		(
				fnameout = (substring fname 1 (fname.count-6)) + "_resized.bones"
				f = fopen fname "rb"
				fo = fopen fnameout "wb"
				
				if f == undefined then format "cant open file %" fname
				else
				(
						clearlistener ()
						read_bone_file f fo scaleSize.value
						fclose f
						fclose fo
				)
		) -- fname
)

---------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------- SKLS
---------------------------------------------------------------------------------------------------------------------------------------------

on resizeAnim pressed do
(
	
	Mult = scaleSize.value
	fname = getopenfilename types:"xray single anim (*.skl)|*.skl|xray anim pack (*.skls)|*.skls|"
	
	if fname != undefined then
	(
		clearlistener ()
		f = fopen fname "rb"
		if f == undefined then messagebox "cant open file"
		else
		(
			fpath = getfilenamepath fname
			ftype = getfilenametype fname
			fnameout = fpath + "transformed_" + (getfilenamefile fname) + ftype
			fo = fopen fnameout "wb"
			
			format "fout = %\n" fo
			
			if ftype == ".skl" then
			(
				CopyData f fo 8
				NumAnims = 1
			)
			else
			(
				NumAnims = readlong f
				writelong fo NumAnims
			)
			
			str = undefined
			
			for i = 1 to NumAnims do
			(
				while true do
				(
					str = readstring f
					if str == undefined then exit
					if str.count > 0 then exit
					writebyte fo 0
				)
				
				format "animation name = %\n" str
				writestring fo str
				CopyData f fo 33
				NumBones = readshort f ; format "\tnum bones = %\n" NumBones
				writeshort fo NumBones
				
				for j = 1 to NumBones do
				(
					str = readstring f ; format "\tbone name = %\n" str
					writestring fo str
					writebyte fo (readbyte f)
					
					for n = 1 to 6 do
					(
						writeshort fo (readshort f)
						NumKeys = readshort f --; format "\t\tnum keys = %\n" NumKeys
						writeshort fo NumKeys
						
						for k = 1 to NumKeys do
						(
							v = readfloat f
							if n<4 then writefloat fo (v*Mult) else writefloat fo v
							writefloat fo (readfloat f)
							writebyte fo (readbyte f)
						)
					)
				)
			)
			
			if ftype == ".skl" then writelong fo 0
			fclose fo
			fclose f
		)
	)
) -- do


) -- roll

try (closeRolloutFloater xr_scaler_flo) catch ()
xr_scaler_flo = newRolloutFloater "x-ray tools" 180 180 40 130
addRollout  xr_scaler_rol xr_scaler_flo


