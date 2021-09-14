rollout xray_omf_edit_rol "omf editor"
(
button GetFileBtn "Load anims from file"
MultiListBox AList "anims" items:#() height:28

button DeleteAnimBtn "Delete" across:3 align:#left width:90
button ReplaceAnimBtn "Replace" align:#center width:90 enabled:false
button AppendAnimBtn "Append" align:#right width:90

checkbox Backup "backup original file" checked:true enabled:false

local AnimList = #(), OfsList = #()
local fname = undefined

------------------------------------------------------------------------------------------------------------
fn ReadSuperString f =
(
		local str = "" , ch, b
		while true do
		(
				b = readbyte f
				if (b == 0) or (b==10) then return str
				append str (bit.intaschar b)
		)
)

------------------------------------------------------------------------------------------------------------
fn writeSuperString f str =
(
		local i
		for i = 1 to str.count do writebyte f (bit.charasint str[i])
		writebyte f 10
)

------------------------------------------------------------------------------------------------------------
fn CopyData f1 f2 N =
(
		local ni = floor (N/4)
		local nb = N - (ni*4)
		local i
		
		for i = 1 to ni do writelong f2 (readlong f1)
		for i = 1 to nb do writebyte f2 (readbyte f1)
)

------------------------------------------------------------------------------------------------------------
fn ReadBoneData f =
(
	local res = #(), cnt
	res[1] = ftell f
	
	format "------------------------------------------------- bone settings data\n"
	sectionId = readlong f ; SectionSize = readlong f #unsigned
	if sectionId != 0xF then (format "not supported format 0xF\n" ; return undefined)
	
	Num1 = readshort f --; format "Num1 = %\n" Num1
	Num2 = readshort f --; format "Num2 = %\n" Num2
	
	for i = 1 to Num2 do
	(
			str1 = readstring f ; format "bone set % = %\n" i str1
			cnt = readshort f
			
			for j = 1 to cnt do
			(
					str = readstring f
					if str == "" then b = readbyte f
					else b = readshort f
					bone_index = readshort f
					format "\t%, %\n" str b
			)
	)
	
	cnt = readshort f
	
	for i = 1 to cnt do
	(
			str = readstring f
			--fseek f 24 #seek_cur
			a1 = readlong f
			a2 = readshort f -- -1
			a3 = readshort f -- index-1
			a4 = for k = 1 to 4 collect readfloat f
			
		 	cnt2 = readlong f
			
			--format "%:% [%], [%], %\n" a3 str a1 a2 a4
			
			for j = 1 to cnt2 do
			(
					str = trimright (ReadSuperString f)
					cnt3 = readlong f
					--fseek f (cnt3 * 8) #seek_cur
					--format "\t\t% [%] %\n" str cnt3 (for kk = 1 to cnt3 collect #(readfloat f,readfloat f))
					for kk = 1 to cnt3 collect #(readfloat f,readfloat f)
			)
	)
				
	res[2] = ftell f
	res
)

----------------------------------------------------------------------------------------------------------------------------------------------
fn GetList fname =
(
	if not doesfileexist fname then (format "file not exist (%)\n" fname ; return undefined)
	f = fopen fname "rb"
	if f == undefined then (format "Cant open file %\n" fname ; return undefined)
	
	local res = #()
	local sectionId = readlong f
	local SectionSize = readlong f #unsigned
	if sectionId != 0xE then (format "not supported format 0xE\n" ; return undefined)
	
	sectionId = readlong f ; SectionSize = readlong f #unsigned
	if sectionId != 0 or SectionSize != 4 then (format "not supported format 0\n" ; return undefined)
	local NumAnims1 = readlong f
	
	for i = 1 to NumAnims1 do
	(
			sectionId = readlong f ; SectionSize = readlong f #unsigned
			CurPos = ftell f
			Ofs = CurPos + SectionSize
			str = readstring f
			--format "%:%\n" sectionId str
			fseek f ofs #seek_set
			append res str
	)

	ReadBoneData f
	
	fclose f
	
	return res
) -- fn get list 


------------------------------------------------------------------------------------------------------------------------------------------------
on GetFileBtn pressed do
(
	fname = getopenfilename types:"omf|*.omf|"
	if fname != undefined then 
	(
		clearlistener ()
		TempArray = GetList fname
		if TempArray != undefined then 
		(
			AList.caption = "file:.." + (substring fname (fname.count-40) -1) + " [" + (TempArray.count as string) + " anims]"
			AList.items = TempArray 
		)
	)
)

------------------------------------------------------------------------------------------------------------------------------------------------ APPEND
fn AppendFile f1 f2 fo =
(
	local sectionId = readlong f1
	local SectionSize = readlong f1 #unsigned
	if sectionId != 0xE then (format "not supported format 0xE\n" ; return undefined)
	
	writelong fo sectionId
	writelong fo 0			-- data size
	
	sectionId = readlong f1 ; SectionSize = readlong f1 #unsigned
	if sectionId != 0 or SectionSize != 4 then (format "not supported format 0\n" ; return undefined)
	local NumAnims1 = readlong f1 ; format "NumAnims1 = %\n" NumAnims1
	
	writelong fo sectionId
	writelong fo 4
	writelong fo 0			-- num anims
	
	format "------------------------------------------------- coping old anims\n" ---------------------------------------------------- copy old
	for i = 1 to NumAnims1 do
	(
		sectionId = readlong f1 ; SectionSize = readlong f1 #unsigned
		CurPos = ftell f1
		Ofs = CurPos + SectionSize
		str = readstring f1
		format "%:%\n" sectionId str
		
		writelong fo sectionId
		writelong fo SectionSize
		
		fseek f1 CurPos #seek_set
		CopyData f1 fo (SectionSize)
	)
	
	local AnimID = sectionId
	
	format "------------------------------------------------- coping new anims\n"
	sectionId = readlong f2 ; SectionSize = readlong f2 #unsigned
	if sectionId != 0xE then (format "not supported format f2 0xE\n" ; return undefined)
	sectionId = readlong f2 ; SectionSize = readlong f2 #unsigned
	if sectionId != 0 or SectionSize != 4 then (format "not supported format f2 0\n" ; return undefined)
	local NumAnims2 = readlong f2 ; format "NumAnims2 = %\n" NumAnims2
	
	for i = 1 to NumAnims2 do
	(
		sectionId = readlong f2 ; SectionSize = readlong f2 #unsigned
		CurPos = ftell f2
		Ofs = CurPos + SectionSize
		str = readstring f2
		format "%:%\n" (i + NumAnims1) str
		
		writelong fo (i + NumAnims1) ; writelong fo SectionSize
		fseek f2 CurPos #seek_set
		CopyData f2 fo (SectionSize)
		
		--fseek f2 ofs #seek_set
	)
	
	DataSize1 = (ftell fo) - 20
	AnimationsCount = NumAnims1 + NumAnims2
	
	format "------------------------------------------------- coping old setting\n"
	sectionId = readlong f1 ; SectionSize = readlong f1 #unsigned
	if sectionId != 0xF then (format "not supported format 0xF\n" ; return undefined)
	writelong fo sectionId ; writelong fo SectionSize
	local ChangeDataSizeOfs2 = (ftell fo) - 4
	
	Num1 = readshort f1 ; format "Num1 = %\n" Num1
	Num2 = readshort f1 ; format "Num2 = %\n" Num2
	writeshort fo Num1 ; writeshort fo Num2 
	
	for i = 1 to Num2 do
	(
			str1 = readstring f1 ; format "bone set % = %\n" i str1
			cnt = readshort f1
			writestring fo str1 ; writeshort fo cnt
			
			for j = 1 to cnt do
			(
					str = readstring f1 ; writestring fo str
					writelong fo (readlong f1)
					format "\t%\n" str
			)
	)
	
	cnt = readshort f1 ; writeshort fo (cnt + NumAnims2)
	
	for i = 1 to cnt do
	(
			str = readstring f1 ; writestring fo str
			CopyData f1 fo 24
			cnt2 = readlong f1 ; writelong fo cnt2
			
			format ":%\n" str
			
			for j = 1 to cnt2 do
			(
					str = ReadSuperString f1 ; writeSuperString fo str
					cnt3 = readlong f1 ; writelong fo cnt3
					CopyData f1 fo (cnt3 * 8)
			)
	)

	format "------------------------------------------------- coping new setting\n"
	sectionId = readlong f2 ; SectionSize = readlong f2 #unsigned
	if sectionId != 0xF then (format "not supported format f2 0xF\n" ; return undefined)
	
	Num1 = readshort f2 ; Num2 = readshort f2
	
	for i = 1 to Num2 do -- pass bone sets
	(
			str1 = readstring f2
			cnt = readshort f2

			for j = 1 to cnt do
			(
					str = readstring f2
					b =readlong f2
			)
	)
	
	cnt = readshort f2
	
	for i = 1 to cnt do
	(
			str = readstring f2 ; writestring fo str
			b = for j = 1 to 4 collect readshort f2
			for j = 1 to 3 do writeshort fo b[j]
			writeshort fo (NumAnims1 + i - 1)
			
			CopyData f2 fo 16
			
			cnt2 = readlong f2 ; writelong fo cnt2
			
			format ":%\n" str
			
			for j = 1 to cnt2 do
			(
					str = ReadSuperString f2 ; writeSuperString fo str
					cnt3 = readlong f2 ; writelong fo cnt3
					CopyData f2 fo (cnt3 * 8)
			)
	)
	
	EndFilePos = ftell fo
	
	---------------------------------------- changes
	fseek fo 4 #seek_set
	writelong fo (DataSize1 + 12)
	fseek fo 16 #seek_set
	writelong fo (NumAnims1 + NumAnims2)
	fseek fo ChangeDataSizeOfs2 #seek_set
	writelong fo (EndFilePos - ChangeDataSizeOfs2 - 4)
	
	return true
)

on AppendAnimBtn pressed do
(
	itsok = false
	if fname == undefined then messagebox "load omf first"
	else
	(
		f1 = fopen fname "rb"
		if f1 == undefined then messagebox "cant open source file"
		else
		(
			append_name = getopenfilename types:"omf|*.omf|"
			if append_name != undefined then
			(
				f2 = fopen append_name "rb"
				if f2 == undefined then messagebox "cant open file"
				else
				(
					NewFilePath = getfilenamepath fname
					Newfilename = NewFilePath + (getfilenamefile fname) + "_edit1234452s5341sd"
					fo = fopen NewFileName "wb"
					if fo == undefined then messagebox "cant create file"
					else
					(
						clearlistener ()
						itsok = AppendFile f1 f2 fo
					)
				)
			)
		)
		
		fclose f1
		fclose f2
		fclose fo
		
		if itsok == true then
		(
			format "\n\nappend: OK\n"
			
			if Backup.checked then
			(
				newname = fname
				i = 1
				
				while true do
				(
					newname = fname + "." + (i as string) + ".bak"
					if not doesfileexist newname then exit
					i += 1
				)
				
				format "original renamed: %\n" newname
				itsok = renamefile fname newname
			)
			else itsok = deletefile fname
			
			renamefile Newfilename fname
			
			TempArray = GetList fname
			if TempArray != undefined then 
			(
				AList.caption = "file:.." + (substring fname (fname.count-40) -1) + " [" + (TempArray.count as string) + " anims]"
				AList.items = TempArray 
			)
		)
	)
)


------------------------------------------------------------------------------------------------------------------------------------------------ DELETE
on DeleteAnimBtn pressed do
(
	itsok = false
	if fname == undefined then messagebox "load omf first"
	else
	(
		clearlistener ()
		ind = AList.selection
		DelNum = ind.numberset
		NewFilePath = getfilenamepath fname
		Newfilename = NewFilePath + (getfilenamefile fname) + "_edited.omf"
		fo = fopen NewFileName "wb"
		if fo == undefined then messagebox "cant create file"
		else
		(
			f = fopen fname "rb"
			if f == undefined then messagebox "cant open file"
			else
			(
				sectionId = readlong f ; SectionSize = readlong f #unsigned -- header
				writelong fo sectionId ; writelong fo 0
				
				sectionId = readlong f ; SectionSize = readlong f #unsigned -- num anims
				writelong fo sectionId ; writelong fo SectionSize
				NumAnims1 = readlong f
				writelong fo (NumAnims1 - DelNum)
				
				DeletedCnt = 0
				IndexId = 0
				
				for i = 1 to NumAnims1 do
				(
					sectionId = readlong f ; SectionSize = readlong f #unsigned
					CurPos = ftell f
					Ofs = CurPos + SectionSize
					if ind[i] == true then 
					(
						DeletedCnt += 1
						format "pass data %\n" i
						fseek f SectionSize #seek_cur
						continue
					)
					
					IndexId += 1
					writelong fo (IndexId) ; writelong fo SectionSize
					CopyData f fo (SectionSize)
				)
				
				DataSize1 = (ftell fo) - 8
				
				sectionId = readlong f ; SectionSize = readlong f #unsigned
				writelong fo sectionId ; writelong fo SectionSize
				ChangeDataSizeOfs = (ftell fo) - 4
				
				Num1 = readshort f ; format "Num1 = %\n" Num1
				Num2 = readshort f ; format "Num2 = %\n" Num2
				writeshort fo Num1 ; writeshort fo Num2
				
				for i = 1 to Num2 do
				(
						str1 = readstring f ; format "bone set % = %\n" i str1
						cnt = readshort f
						writestring fo str1 ; writeshort fo cnt
						
						for j = 1 to cnt do
						(
								str = readstring f ; writestring fo str
								writelong fo (readlong f)
								format "\t%\n" str
						)
				)
				
				cnt = readshort f ; writeshort fo (cnt - DelNum)
				IndexId = 0
				
				for i = 1 to cnt do
				(
						str = readstring f
						if ind[i] == false then
						(
							--CopyData f fo 24
							writestring fo str
							writelong fo (readlong f) -- always 2
							writeshort fo (readshort f) -- always -1
							readshort f -- old index
							writeshort fo IndexId
							IndexId += 1
							CopyData f fo 16
						)
						else fseek f 24 #seek_cur
						
					 	cnt2 = readlong f
						if ind[i] == false then writelong fo cnt2
						
						format ":%\n" str
						
						for j = 1 to cnt2 do
						(
								str = ReadSuperString f
								if ind[i] == false then writeSuperString fo str
								cnt3 = readlong f
								if ind[i] == false then writelong fo cnt3
								if ind[i] == false then CopyData f fo (cnt3 * 8) else fseek f (cnt3 * 8) #seek_cur
						)
				)
				
				EndFilePos = ftell fo
				fseek fo 4 #seek_set
				writelong fo DataSize1
				fseek fo ChangeDataSizeOfs #seek_set
				writelong fo (EndFilePos - ChangeDataSizeOfs - 4)
				itsok = true
				--deleteFile fname
				--renameFile Newfilename fname
			)
			
			fclose fo
			fclose f
			
			if itsok == true then
			(
				format "\n\nappend: OK\n"
				
				if Backup.checked then
				(
					newname = fname
					i = 1
					
					while true do
					(
						newname = fname + "." + (i as string) + ".bak"
						if not doesfileexist newname then exit
						i += 1
					)
					
					format "original renamed: %\n" newname
					itsok = renamefile fname newname
				)
				else itsok = deletefile fname
				
				renameFile Newfilename fname
				
				TempArray = GetList fname
				if TempArray != undefined then 
				(
					AList.caption = "file:.." + (substring fname (fname.count-40) -1) + " [" + (TempArray.count as string) + " anims]"
					AList.items = TempArray 
				)
			)
		)
	)
)

) -- roll

try (closeRolloutFloater xray_omf_edit_flo) catch ()
xray_omf_edit_flo = newRolloutFloater "s.t.a.l.k.e.r." 350 500 40 130
addRollout  xray_omf_edit_rol xray_omf_edit_flo