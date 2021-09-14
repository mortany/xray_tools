-- anm load

rollout Xray_anm_io_rol "xr anm io"
(

button LoadBtn "Load anm" width:160
button ExportBtn "Export anm" width:160
checkbox CamMode "camera mode"
edittext AnmName "animation name" labelOnTop:true
--button ClrAnimaBtn "clear anim"

checkbox DumpMode "save every X frame" across:2 align:#left checked:true enabled:false
--label step_text "step" across:2 align:#left
spinner dstep type:#integer range:[1,10000,5] align:#right width:40

group ""
(
	checkbox UseParent "relative to object"
	pickbutton ParentPick "Pick parent object" width:160 autoDisplay:true
)
/*
group "reduce keys"
(
checkbox UseReducePos "position" across:2 align:#left
spinner ReducePos range:[0,10000,.1] align:#right width:60
checkbox UseReduceRot "rotation" across:2 align:#left
spinner ReduceRot range:[0,10000,.5] align:#right width:60
)
*/

label lbl_0 "scale" align:#left across:2
spinner scale_value range:[0,100000,1] scale:.001 width:60 align:#right
	
local CSig = #(2,3,1)
local DumpOrder = 4, sig = [-1., -1., -1.]

on ParentPick rightclick do
(
	ParentPick.object = undefined
	ParentPick.text = "Pick parent object"
)

fn ExportAnm f sobj =
(
		local t_step = dstep.value
		local CAM_TM = if CamMode.checked then rotateXMatrix -90 else matrix3 1
		local obj = point axistripod:true size:1 axisLength:1
		obj.position.track = bezier_position()
		obj.rotation.track = euler_xyz axisOrder:DumpOrder
		obj.rotation.track.axisorder = DumpOrder
		local t = animationRange.start
		select obj
		
		if DumpMode.checked then
			animate on
				undo off
					while true do
					(
						TRF = at time t sobj.transform
						PTM = if UseParent.checked then inverse (at time t ParentPick.object.transform) else matrix3 1
						at time t obj.transform = CAM_TM*(TRF * PTM)
						t += t_step
						if t == animationRange.end + t_step then exit
						if t > animationRange.end then t = animationRange.end
					)
		else
					(
						
					)
				
		format "-- dumping helper done\n"
		
		deleteKeys obj.scale.controller.keys
		--if UseReducePos.checked then reduceKeys obj.position.track ReducePos.value 1f
		--if UseReduceRot.checked then reduceKeys obj.rotation.track ReduceRot.value 1f
		
		local FRate = 30.
		writelong f 4352	-- header
		writelong f 0		-- data size
		writestring f AnmName.text -- writebyte f 0
		writelong f animationrange.start		-- start frame
		writelong f animationrange.end			-- end frame
		writefloat f FRate	-- frame rate
		writeshort f 5		-- unk
		
		c = obj.position.controller
		
		for j = 1 to 3 do
		(
				writebyte f 1 -- unk
				writebyte f 1 -- unk
				writeshort f c.keys.count
				
				for k in c.keys do
				(
						t = k.time
						v = at time t obj.position
						v = if j == 1 then v.x else if j == 2 then v.z else v.y
						writefloat f (v*scale_value.value)
						writefloat f ((t as float)/4800.)
						writebyte f 0 ; for i = 1 to 7 do writeshort f -32768
				)
				format "-- controller position[%] done\n" j
		)
		
		c = obj.rotation.controller
		cc = #()
		cc[CSig[1]] = obj.rotation.x_rotation.track
		cc[CSig[2]] = obj.rotation.y_rotation.track
		cc[CSig[3]] = obj.rotation.z_rotation.track
		
		for j = 1 to 3 do
		(
				writebyte f 1 -- unk
				writebyte f 1 -- unk
				numkes = c.keys.count
				if numkes > 0 then 
				(
					writeshort f numkes
				
					for k in cc[j].keys do
					(
							t = k.time
							v = (at time t cc[j].value)*sig[j]
							writefloat f (degtorad v)
							writefloat f ((t as float)/4800.)
							writebyte f 0 ; for i = 1 to 7 do writeshort f -32768
					)
				)
				else
				(
					writeshort f 1
					t = animationrange.start
					v = (at time t cc[j].value)*sig[j]
					writefloat f (degtorad v)
					writefloat f ((t as float)/4800.)
					writebyte f 0 ; for i = 1 to 7 do writeshort f -32768
				)
				
				format "-- controller rotation[%] (numkes = %) done\n" j numkes
		)
		
		local datasize = (ftell f) - 8
		fseek f 4 #seek_set
		writelong f datasize
		delete obj
)


fn LoadAnm f yobj = 
(
	local obj = if CamMode.checked then freeCamera targetDistance:1 fov:38.5 else point axistripod:true size:1 axisLength:1
	select obj
	local i, j, k, u1, NumKeys
	
	if (readlong f) != 4352 then (format "wrong header\n" ; return undefined )
	local datasize = readlong f
	local EndOfs = datasize + 8
	
	--format "Data size = %\n" datasize
	
	local anima_name = readstring f ; format "name:%\n" anima_name
	local StartFrame = readlong f ; format "StartFrame = %\n" StartFrame 
	local EndFrame = readlong f ; format "EndFrame = %\n" EndFrame
	local frate = readfloat f ; format "Frame rate = %\n" frate
	
	u = readshort f ; format "unk short = %\n" u

	local ctr = for j = 1 to 6 collect linear_float ()
	local ctime = linear_float ()
	
	for i = 1 to 6 do
	(
			if (ftell f) >= EndOfs then exit
			u = readbyte f --; format "unk byte = %\n" u
			u = readbyte f --; format "unk byte = %\n" u
			NumKeys = readshort f
			format "Controller %, numkeys = %\n" i NumKeys
			
			for j = 1 to NumKeys do
			(
					KeyVal = readfloat f
					KeyTime = readfloat f
					k = #(readbyte f, readshort f, readshort f, readshort f, readshort f, readshort f, readshort f, readshort f) --; fseek f 15 #seek_cur
					--format "\t key %: time %: value %: %\n" j KeyTime KeyVal k
					
					if obj != undefined then
					(
							t = KeyTime*frate
							animate on at time t ctr[i].value = KeyVal
							addNewKey ctime t
							animate on at time t ctime.value = 1
					)
			)
	) -- i loop

	
	if obj != undefined then
	(
		obj.position.track = bezier_position()
		obj.rotation.track = euler_xyz()
		
		for k in ctime.keys do
		(
			t = k.time
			px = at time t ctr[1].value
			pz = at time t ctr[2].value
			py = at time t ctr[3].value
			rx = at time t ctr[4].value
			rz = at time t ctr[5].value
			ry = at time t ctr[6].value
			
			tm2 = matrix3 1
			tm2 = (rotateZMatrix -(radtodeg rx))*tm2
			tm2 = (rotateXMatrix -(radtodeg rz))*tm2
			tm2 = (rotateYMatrix -(radtodeg ry))*tm2
			tm2.row4 = [px,py,pz]*scale_value.value
			
			PTM = if UseParent.checked then at time t ParentPick.object.transform else matrix3 1
			animate on at time t obj.transform = tm2
			--format "\t\t%: [%,%,%] \n" t px py pz
		)
		
		set animate off
		if CamMode.checked then obj.transform = (rotatexmatrix 90)*obj.transform
		set animate on
	)
	
	AnimationRange = (interval 0 EndFrame)
)


on dumpcam pressed do
(
	t_step = dstep.value
	
	for obj in selection do
	(
		b = point axistripod:true size:1 axisLength:1
		b.parent = undefined
		b.position.track = bezier_position()
		b.rotation.track = euler_xyz axisOrder:DumpOrder
		b.rotation.track.axisorder = DumpOrder
		t = animationRange.start
		
		animate on
			undo off
				while true do
				(
						TRF = at time t obj.transform
						at time t b.transform = TRF
						t += t_step
						if t == animationRange.end + t_step then exit
						if t > animationRange.end then t = animationRange.end
				)
		
		deleteKeys b.scale.controller.keys
		select b
	)
)

---------------------------
on ClrAnimaBtn pressed do
	for obj in selection do
	(
			deletekeys obj.scale.controller.keys #allkeys
			deletekeys obj.position.controller.keys #allkeys
			deletekeys obj.rotation.controller.keys #allkeys
			--obj.transform = matrix3 1
	)
	
---------------------------
on LoadBtn pressed do
(
	if UseParent.checked and (not isvalidnode ParentPick.object) then messagebox "parent node not valid"
	else
	(
		fname = getopenfilename types:"xray anm|*.anm|" \
				filename:"C:\\Program Files\\X-Ray CoP SDK\\editors\\gamedata\\anims\\camera_effects\\scenario_cam\\pripyat\\"
		
		if fname != undefined then
		(
				f = fopen fname "rb"
				
				if f == undefined then format "cant open file\n"
				else
				(
						clearListener ()
						format "------- %\n" fname
						--with redraw off 
							LoadAnm f selection[1]
						fclose f
				)
		)
	)
)
---------------------------
on ExportBtn pressed do if $ != undefined then
(
	if UseParent.checked and (not isvalidnode ParentPick.object) then messagebox "parent node not valid"
	else
	(
		fname = getsavefilename types:"xray anm|*.anm|" \
				filename:"C:\\Program Files\\X-Ray CoP SDK\\editors\\Import\\"
		if fname != undefined then 
		(
				f = fopen fname "wb+"
				if f == undefined then format "cant create file\n"
				else
				(
						clearListener ()
						ExportAnm f selection[1]
						fclose f
				)
		)
	)
)


) -- roll

try (closeRolloutFloater Xray_anm_io_flo) catch ()
Xray_anm_io_flo = newRolloutFloater "x-ray tools" 200 270 40 330
addRollout  Xray_anm_io_rol Xray_anm_io_flo











