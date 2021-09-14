rollout XRay_Skeleton_rol "x-ray load *.skls v.10"
(
button CreateList "Get animation file" width:230
label FLabel "" align:#left
label ALabel "animations:" align:#left
listbox AnimList items:#() height:16
button LoadAnim "LOAD MOTION" height:30 width:230
label lbl_0 "scale factor" align:#left across:2
spinner ScaleFactor range:[0,100000,1]  width:60 align:#right
label lbl_1 "time stretch" align:#left across:2
spinner ScaleTimeFactor range:[0,100000,1]  width:60 align:#right
checkbox SetARange "set animation range" across:2 align:#left
checkbox FromZero "leave start" align:#right checked:true
button ResetPoseBtn "Reset pose"
--checkbox LoadUntilChk "load until frame" across:2 align:#left
--spinner MaxLoadTime type:#integer range:[0,999999,100] align:#right


struct s_anim_name ( name, index )
local AnimFileName = undefined, Animas = #(), LastAnimPath = undefined
local flagNames = #("type fx","stop at end","no mix","sync part","use foot step","move xform","idle","use weapon bone")

fn FNSortAnim v1 v2 =
(
		d = stricmp v1.name v2.name
		case  of
		(
				(d < 0 ) : -1
				(d > 0 ) : 1
				default: 0
		)
)

--------------------------------------------------------------------------------------------------------------------------------------------------
fn PassAnimation f =
(
		local i, j, u, count, BoneName, flagStr = ""
		local a1 = readlong f
		local a2 = readlong f
		--fseek f 25 #seek_cur
		local FRate = readfloat f, UnkShort1 = readshort f , flagi = readbyte f , UnkShort2 = readshort f
		
		if flagi > 0 then 
			for i = 0 to 7 do if (bit.and flagi (2^i)) > 0 then flagStr += flagNames[i+1] + "|"
		
		local ASpeed = readfloat f , AAccure = readfloat f, AFallof = readfloat f, UnkFloat1 = readfloat f, NumBones = readshort f
		
		--format "% % % [%]\n" a1 a2 NumBones (ftell f)
		
		for i = 1 to NumBones do
		(
				BoneName = readstring f
				u = readbyte f
				--format "\t%, %\n" BoneName u
		
				for j = 1 to 6 do
				(
						readbyte f
						readbyte f
						count = readshort f --; format "\t\t%\n" count 
						fseek f (count*9) #seek_cur
				)
		) -- i
		
		--readlong f
		
		return #(a1,a2,ASpeed,AAccure,AFallof,flagStr)
)

--------------------------------------------------------------------------------------------------------------------------------------------------
fn load_single_skl f start_t =
(
		local AName
		
		while true do
		(
			AName = readstring f
			if AName == undefined then exit
			if AName.count > 0 then exit
		)
		
		format "animation: %\n" AName
		local FStart = readlong f , FEnd = readlong f ; format "frames from % to %\n" FStart FEnd 
		local FRate = readfloat f ; format "frame rate : %\n" FRate 
		local UnkShort1 = readshort f , flagi = readbyte f , UnkShort2 = readshort f --; format "unk : %, %, %\n" UnkShort1 UnkByte1 UnkShort2
		
		if flagi > 0 then 
		(
			format "flags: "
			for i = 0 to 7 do if (bit.and flagi (2^i)) > 0 then format "% | " flagNames[i+1]
			format "\n"
		)
		
		local ASpeed = readfloat f , AAccure = readfloat f, AFallof = readfloat f ; format "speed,acure,fallof | %, %, %\n" ASpeed AAccure AFallof 
		local UnkFloat1 = readfloat f ; format "UnkFloat1 = %\n" UnkFloat1
		local NumBones = readshort f ; format "num animated bones = %\n" NumBones
		local ctime, ctr
		local ControllerName = #("position.1","position.2","position.3","rotation.1","rotation.2","rotation.3")
		local MinTime, MaxTime
		
		for i = 1 to NumBones do
		(
				BoneName = readstring f 
				u = readbyte f
				
				--bo = execute ("$" + BoneName)
				bo = undefined
				
				for xo in selection do 
					if (stricmp BoneName xo.name) == 0 then (bo = xo ; exit)
					
				--if bo == undefined then ( format "### warning: BONE OBJECT NOT FOUNDED [%]\n" BoneName)
				--else format "bone: %\n" BoneName

				ctr = for j = 1 to 6 collect linear_float ()
				ctime = linear_float ()
				
				
				for j = 1 to 6 do
				(
						u = #(readbyte f, readbyte f)
						count = readshort f
						--format "\t Controller % : %, %\n" j u count
						--if count > 0 then format "\t% [%]\n" ControllerName[j] count
						
						for k = 1 to count do
						(
								v = readfloat f
								t = (readfloat f)*FRate*ScaleTimeFactor.value + start_t
								b = readbyte f
								animate on at time t ctr[j].value = v
								addNewKey ctime t
								animate on at time t ctime.value = 1
								--format "\t\t %| %\n" t (if j > 3 then (radtodeg v) else v)
						)
				)
				
				
				if bo != undefined then
				(
						setBeforeORT bo.rotation.controller #constant
						setAfterORT bo.rotation.controller #constant
						setBeforeORT bo.position.controller #constant
						setAfterORT bo.position.controller #constant
					
						for k in ctime.keys do
						(
							t = k.time
							px = at time t (ScaleFactor.value * ctr[1].value)
							pz = at time t (ScaleFactor.value * ctr[2].value)
							py = at time t  (ScaleFactor.value * ctr[3].value)
							rx = radtodeg (at time t ctr[4].value)
							rz = radtodeg (at time t ctr[5].value)
							ry = radtodeg (at time t ctr[6].value)
							
							animate on at time t bo.rotation.controller.value = eulertoquat (eulerangles -ry -rz -rx) order:4
							animate on at time t bo.position.controller.value = [px,py,pz]
						)
						
						deletekeys bo.scale.controller.keys #allkeys
				)
				
				if ctime.keys.count > 0 then
				(
					if MinTime == undefined then (MinTime = ctime.keys[1].time; MaxTime = ctime.keys[ctime.keys.count].time)
					else
					(
						if ctime.keys[ctime.keys.count].time > MaxTime then MaxTime = ctime.keys[ctime.keys.count].time
						if ctime.keys[1].time < MinTime then MinTime = ctime.keys[1].time
					)
				)
		) -- i
		
		if FromZero.checked then MinTime = animationrange.start
			
		if MinTime!=undefined and SetARange.checked then
			if MinTime == MaxTime then animationRange = interval MaxTime (MaxTime+1)
			else animationRange = interval MinTime MaxTime
		
		---format "qweqwe %\n" ctime.keys.count
		
		if MaxTime!=undefined then slidertime = MaxTime

		--if SetARange.checked then
			--if (FEnd-1) > 0 then animationRange = interval 0 (FEnd-1+start_t) else animationRange = interval 0 (FStart+1+start_t)
)

--------------------------------------------------------------------------------------------------------
on AnimList selected N do -- (Animas[AnimList.selection].index as string)
(
	--ALabel.text = "Animations: (selected " + (N as string) + "/" + (AnimList.items.count as string) + ")"
	ALabel.text = "Animations: (selected " + (Animas[N].index as string) + "/" + (AnimList.items.count as string) + ")"
)

--------------------------------------------------------------------------------------------------------
on ResetPoseBtn pressed do
(
		sliderTime = 0
		
		for obj in selection do
		(
				deletekeys obj.pos.controller
				deletekeys obj.rotation.controller
				deletekeys obj.scale.controller
				obj.assumeSkinPose()
		)
)
	
--------------------------------------------------------------------------------------------------------
on CreateList pressed do
(
		if LastAnimPath == undefined then LastAnimPath = (getIniSetting (scriptspath + "xr_scripts_settings.txt") "paths" "editorpath") + "\\"
		fname = getopenfilename types:"anims|*.skls|anim|*.skl|" filename:LastAnimPath
		
		clearlistener ()
		str = ""
		
		if fname != undefined then
		(
				f = fopen fname "rb"
				if f == undefined then format "cant open file\n"
				else
				(
						LastAnimPath = getfilenamepath fname
						AnimList.items = #()
						AnimFileName = fname
						NumAnims = readlong f
						if NumAnims == 4608 then (NumAnims = 1 ; readlong f)
					
						format "Num anims = %\n\n" NumAnims
						TempList = #()
						Animas = #()
						
						for i = 1 to NumAnims do
						(
								while true do
								(
									str = readstring f
									if str == undefined then exit
									if str.count > 0 then exit
								)
								j = s_anim_name name:(str) index:i
								append Animas j
								b = PassAnimation f
								format "%,\t frames %, speed %, accure %, fallof %" str b[2] b[3]  b[4]  b[5]
								if b[6] == "" then format "\n" else format ", flags |%\n" b[6]
						)
						
						--print Animas
						qsort Animas FNSortAnim
						--print Animas
						
						AnimList.items = for i in Animas collect i.name
						FLabel.text = "file:" + (filenamefrompath fname)
						ALabel.text = "animations: (selected " + (Animas[1].index as string) + "/" + (AnimList.items.count as string) + ")"
						AnimList.selection = 1
						fclose f
				)
		)
)

--------------------------------------------------------------------------------------------------------
on LoadAnim pressed do
(
		if AnimFileName != undefined then
		(
				clearlistener ()
				
				f = fopen AnimFileName "rb"
				if f == undefined then format "cant open file\n"
				else
				(
						NumAnims = readlong f
						if NumAnims == 4608 then (NumAnims = 1 ; readlong f) --single
						--N = AnimList.selection
						N = Animas[AnimList.selection].index
						
						for i = 1 to N-1 do
						(
								while true do
								(
									str = readstring f
									if str == undefined then exit
									if str.count > 0 then exit
								)
								PassAnimation f
						)
						
						load_single_skl f sliderTime
						fclose f
				)
		)
)

) -- roll


try (closeRolloutFloater XRay_Skeleton_flo) catch ()
XRay_Skeleton_flo = newRolloutFloater "x-ray tools" 270 450 40 130
addRollout  XRay_Skeleton_rol XRay_Skeleton_flo











