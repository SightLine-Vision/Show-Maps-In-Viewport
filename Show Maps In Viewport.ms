/*
[INFO]

NAME = Show Maps In Viewport
VERSION = 1.0.1
AUTHOR = MastaMan
DEV = ViscoCG
HELP = \help\showMapsInViewport.html

[INSTALL]
MACRO=Show_Maps
CAT=ViscoCG
TEXT=SM
ICON=#("Material_Modifiers", 4)

[1.0.0]

* First release =

[1.0.1]

+ Added: Progress bar=

[ABOUT]

Simple script for display maps in viewport.=
_=
Support renderers:=
V-Ray=
Corona=
Scanline=

@=
Supported types:=
-Material=
-Diffuse=
-Ambient=
-Bump=

[TEST]


[SCRIPT]

*/


fn getScriptInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	
	r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" collect i
	
	return #(n, a, v, o, r, c, h)
)

fn writeFile f s =
(			
	f = createFile f mode: "wt"

	format(s as string) to:f

	flush f
	close f
)

fn parseIniLine m = 
(
	if(m.count == 0) do return ""
	
	l = ""	

	try
	(
		for i in m do 
		(	
			if(i[1] == "_") do 
			(
				l += "_______________________________________\r\n\r\n" 
				continue
			)
			if(i[1] == "@") do 
			(
				l += "\r\n"
				continue
			)
			
			l += i + "\r\n"
		)
	) catch()
	return l
)


fn useSettings k p w =
(	
	d = getFilenamePath  (getThisScriptFilename())
	n = filenameFromPath (getThisScriptFilename())			
	settingsFile = d + @"ini\" + (sysInfo.username) + "_" + n + ".ini"
	szUser = sysInfo.computername
	case w of
	(
		"r":
		(
			s = getINISetting settingsFile szUser k
			case p of
			(
				"int": return s as integer
				"float": return s as float
				"bool": if s == "true" then true else false
				default: return s
			)
		)
		default: return setINISetting settingsFile szUser k (p as string)
	)
)

fn getRenderer =
(
	r = renderers.current as string
	
	if matchpattern r pattern:"*Corona*" do return "Corona"
	if matchpattern r pattern:"*V_Ray_Adv*" do return "Vray"
	if matchpattern r pattern:"*Default_Scanline*" do return "Scanline"
	if matchpattern r pattern:"*mental_ray*" do return "Mental"
	if matchpattern r pattern:"*iray_Renderer*" do return "IRay"
		
	return ""
)

try(closeRolloutFloater fShowMaps)catch()
global fShowMaps = newRolloutFloater "Show Maps" 230 300
global supportTypes = #(#("", ""))
	
	
global typesStandard = #(
	#(Standard),
	#("Diffuse", "diffuseMap"),
	#("Ambient", "ambientMap"),
	#("Specular", "specularMap"),
	#("Reflection", "reflectionMap"),
	#("Refraction", "refractionMap"),
	#("Bump", "bumpMap")	
)

global typesVray = #(
	#(VrayMtl),
	#("Diffuse", "texmap_diffuse"),
	#("Reflection", "texmap_reflection"),
	#("Refraction", "texmap_refraction"),
	#("Bump", "texmap_bump")	
)

global typesCorona = #(
	#(CoronaMtl),
	#("Diffuse", "texmapDiffuse"),
	#("Reflection", "texmapReflect"),
	#("Refraction", "texmapRefract"),
	#("Bump", "texmapBump")	
)

fn getMaterials = 
(
	mtl = #()
	for t in supportTypes[1] where t != "" do
	(	
		for o in selection do for m in getClassInstances t target: o do appendIfUnique mtl m
	)
	
	return mtl
)

/* //////////////////////////////////////////////////////////////////////// */

fn showInViewport id mtl =
(
	progressStart "Show Maps In Viewport..."
	escapeEnable
	
	disableSceneRedraw()
	
	i = 0
	for m in mtl do
	(
		if(id == 1) do
		(
			m.showInViewport = on
			return true
		)
		
		t = supportTypes[id][2]
		
		i += 1
		
		progressUpdate (100.0 * i / mtl.count)
		if(getProgressCancel() == true)do exit	
		
		b = undefined
		if(not hasProperty m t) do continue
		
		b = getProperty m t 
		
		if(b == undefined) do continue
		
		m.showInViewport = on
		showTextureMap m b on		
	)
	
	enableSceneRedraw()
	
	progressEnd()
)	
	
/* //////////////////////////////////////////////////////////////////////// */

rollout rShowMaps "Map Type" 
(			
	dropdownlist ddlTypes "Select type:" items: #("Material")
	button btnShowMap "Show Maps In Viewport" offset: [0, 15]
	timer tmrShow "" active: false interval: 10
	
	on rShowMaps open do
	(
		r = getRenderer()
			print r	
		supportTypes = case r of
		(
			"Corona": typesCorona
			"Vray": typesVray
			"Scanline": typesStandard
			default: #(#("", ""))
		)
		
		items = #("Material")
		for i in 2 to supportTypes.count do append items supportTypes[i][1]
		
		ddlTypes.items = items
	)
		
	on tmrShow tick do
	(
		r = getRenderer()
			
		mtl = getMaterials()
		
		if(selection.count == 0) do
		(
			messageBox "Please select objects!" title: "Warning!"
			tmrShow.active = false
			return false
		)
		
		if(mtl.count == 0) do 
		(
			messageBox "No materials on selected objects!" title: "Warning!"
			tmrShow.active = false
			return false
		)
		
		id = ddlTypes.selection 

		case r of 
		(
			"Scanline": showInViewport id mtl
			"Corona": showInViewport id mtl
			"Vray": showInViewport id mtl
			default: messageBox "You are used unsupported renderer!" title: "Warning!"
		)			
		
		tmrShow.active = false
	)
	
	on btnShowMap pressed do tmrShow.active = true
)

rollout rAbout "About" 
(	
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	button btnHelp "Help" enabled: false
	
	fn getHelp run: false =
	(
		s = getThisScriptFilename()
		i = getScriptInfo s
		szHelp = (getFilenamePath s) + i[7]
		if(i[7] != "" and doesFileExist szHelp) do btnHelp.enabled = true
			
		if(run) do ShellLaunch szHelp ""
	)
	
	on btnHelp pressed do getHelp run: true
				
	on rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
		
		getHelp()
	)
)

addRollout rShowMaps fShowMaps rolledUp:false 
addRollout rAbout fShowMaps rolledUp:true 