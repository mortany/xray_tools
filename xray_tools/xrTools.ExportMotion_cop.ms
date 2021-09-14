rollout xray_export_skl_rol "export motion (*.skl) ver.10"
(
	button exportBtn "Export motion" width:160 --across:2
	radiobuttons ExportType labels:#("skl","skls","skls+") columns:3
	edittext NewAnimationName "name" width:160
	
	spinner SFrame type:#integer width:50 range:[-999999,999999,0] across:3 align:#left
	spinner EFrame type:#integer width:50 range:[-999999,999999,100] offset:[4,0]
	button GetAnimRange "*" align:#right height:16
	pickbutton RootPick "no root selected" width:160 autoDisplay:true
	checkbox IncludeRoot "include root"

	group ""
	(
	label ssssl "scale factor" align:#left across:2
	spinner scale_pos width:60 align:#right scale:.001 range:[0, 1000000, 1]
	)

	group "flags"
	(
	checkbox StopAtEnd "stop at end" checked:true
	checkbox NoMix "no mix"
	checkbox SyncPart "sync part"
	checkbox UseFootStep "use foot step"
	checkbox MoveXForm "move xform"
	checkbox idle "idle"
	checkbox UseWeaponBone "use weapon bone"
	)

	fn get_hierarchy obj =
	(
			local ch = obj.children, i, res = #(obj)
			
			for i in ch do 
				join res (get_hierarchy i)
			
			return res
	)

	fn get_top_object objs =
	(
			local obj
			
			for obj in objs do
			(
					if obj.parent == undefined then return obj
					if (finditem objs obj.parent) == 0 then return obj
			)
			
			return undefined
	)

	fn Export_anim f objs robj FStart FEnd anim_name extype = 
	(
			local EulerOrder = 5
			local FRate = 30.
			local Timer = timestamp ()
			local AnimationsCount = 0
			local AnimationName = anim_name
			
			if extype == 1 then
			(
				writelong f 4608 	-- skl section ID
				writelong f 0 		-- skl section size
			)
			else if extype == 2 then
			(
				writelong f 1
				AnimationName = NewAnimationName.text
			)
			else
			(
				fseek f 0 #seek_set
				AnimationsCount = readlong f #unsigned
				fseek f 0 #seek_end
				AnimationName = NewAnimationName.text
			)
			
			writestring f AnimationName -- A name
			
			local AStart = FStart --(animationRange.start as integer)/160
			local AEnd = FEnd --(animationRange.end as integer)/160
			local KeysCount = AStart - AEnd
			writelong f 0 --AStart 
			writelong f (AEnd-AStart) --(AEnd-AStart+1)
			
			writefloat f FRate
			
			writeshort f 7 -- objs.count   -- unk "animated bones ?"
			
			flagi = 2*StopAtEnd.triState + 4*NoMix.triState + 8*SyncPart.triState + 16*UseFootStep.triState
			flagi += 32*MoveXForm.triState + 64*idle.triState + 128*UseWeaponBone.triState
			writebyte f flagi

			writeshort f -1   -- unk flags
			writefloat f 1. -- speed
			writefloat f 2. -- accure
			writefloat f 2. -- fallof
			writefloat f 1. -- unk
			writeshort f (objs.count) -- NumBones
			
			local cnt = 1
			
			for obj in objs do
			(
					pushprompt ("[" + (cnt as string) + "/" + (objs.count as string) + "]:" + obj.name )
					cnt += 1
					format "-- %\n" obj.name
					writestring f (xrToolsUtil.renameBone obj.name) -- bone name
					writebyte f 0 -- unk
					
					pobj = obj.parent
					if pobj != undefined then
					(
						i = finditem objs pobj
						if i == 0 then pobj = undefined
					)
					
					i = finditem robj obj
					if (i == 0) and (pobj == undefined) then pobj = if robj.count > 0 then robj[robj.count] else undefined
					
					tms = for t = AStart to AEnd collect \
							#(at time t ((orthogonalize obj.transform) * (if pobj!=undefined then inverse (orthogonalize pobj.transform) else matrix3 1)),(t-AStart)/FRate)
					
					------------------------------------------------------------------------------------------ POSITIONS
					--format "\t writing X-pos:\n"
					writebyte f 1 -- unk
					writebyte f 1 -- unk
					writeshort f tms.count
							
					for i = 1 to tms.count do
					(
							writefloat f (tms[i][1].position.x*scale_pos.value)
							writefloat f tms[i][2]
							writebyte f 4
							--format "\t\t %: %\n" tms[i][2] tms[i][1].position.x
					)
					
					--format "\t writing Z-pos:\n"
					writebyte f 1 -- unk
					writebyte f 1 -- unk
					writeshort f tms.count
							
					for i = 1 to tms.count do
					(
							writefloat f (tms[i][1].position.z*scale_pos.value)
							writefloat f tms[i][2]
							writebyte f 4
							--format "\t\t %: %\n" tms[i][2] tms[i][1].position.z
					)
					
					--format "\t writing Y-pos:\n"
					writebyte f 1 -- unk
					writebyte f 1 -- unk
					writeshort f tms.count
							
					for i = 1 to tms.count do
					(
							writefloat f (tms[i][1].position.y*scale_pos.value)
							writefloat f tms[i][2]
							writebyte f 4
							--format "\t\t %: %\n" tms[i][2] tms[i][1].position.y
					)
					
					----------------------------------------------------------------------------------------- ROTATIONS
					--format "Rotations\n"
					
					for j = 1 to 3 do
					(
							--format "\t writing %:\n" j
							writebyte f 1 -- unk
							writebyte f 1 -- unk
							writeshort f tms.count
							
							for i = 1 to tms.count do
							(
									v = inverse tms[i][1].rotationpart
									v = QuatToEuler v order:EulerOrder
									v = if j == 1 then v.x else if j == 2 then v.y else v.z 
									writefloat f (degtorad v)
									writefloat f tms[i][2]
									writebyte f 4
									--format "\t\t %: %\n" (t/FRate) (degtorad v)
							)
					)
					
			)
			
			writelong f 0
			
			if extype == 1 then
			(
				--writelong f 0
				cursize = ftell f
				fseek f 4 #seek_set
				writelong f (cursize-8)
			)
			else if extype == 3 then
			(
				fseek f 0 #seek_set
				writelong f (AnimationsCount + 1)
			)
			
			timer = (timestamp() - Timer)/1000.
			format "\ndone at % sec\n" timer
			pushprompt ("export done (time = " + (timer as string) + " sec)")
	) -- fn

	--------------------
	on RootPick rightclick do 
	(
		RootPick.object = undefined
		RootPick.text = "no root selected"
	)

	on GetAnimRange pressed do
	(
			SFrame.value = animationRange.start
			EFrame.value = animationRange.end
	)

	on exportBtn pressed do
			if $ == undefined then messagebox "nothing selected"
			else
			(
					clearlistener ()
					parobjs = #()
					
					if IncludeRoot.checked and (IsValidNode RootPick.object) then
					(
						parobjs = get_hierarchy RootPick.object
						objs = for i in parobjs collect i
					)
					else objs = #()
					
					join objs (selection as array)
					
					if objs == undefined then format "error 'objs == undefined'\n"
					else
					(
							if ExportType.state == 1 then
								fname = getsavefilename types:"single animation|*.skl|" filename:"C:\\Program Files\\X-Ray CoP SDK\\editors\\import\\"
							else if ExportType.state == 2 then
								fname = getsavefilename types:"animations|*.skls|" filename:"C:\\Program Files\\X-Ray CoP SDK\\editors\\import\\"
							else if ExportType.state == 3 then
								fname = getopenfilename types:"animations|*.skls|" filename:"C:\\Program Files\\X-Ray CoP SDK\\editors\\import\\"
							else fname == undefined
							
							if fname != undefined then 
							(
								if ExportType.state == 3 then f = fopen fname "rb+"
								else f = fopen fname "wb"
								
								if f == undefined then format "cant create/open file\n"
								else
								(
										format "Num objects = %\n" objs.count
										Export_anim f objs parobjs SFrame.value EFrame.value (getfilenamefile fname) ExportType.state
										fclose f
								)
							)
					)
			)

) -- rol


try (closeRolloutFloater xray_export_skl_flo) catch ()
xray_export_skl_flo = newRolloutFloater "x-ray tools" 200 390 40 130
addRollout  xray_export_skl_rol xray_export_skl_flo










