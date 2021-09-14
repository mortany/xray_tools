-- S.T.A.L.K.E.R. xray tools

try (
	if (maxVersion())[1] < 8000 then throw "In order to use XRAY-TOOLS you need 3DSMax8 or higher"
	fileIn "xrTools.Utils.ms"
	fileIn "xrTools.CAMtl.ms"
	fileIn "xrTools.CollisionShapeDef.ms"
	fileIn "xrTools.gui.ms"
) catch
(
	messagebox (getcurrentexception() as String) title:"S.T.A.L.K.E.R.: XRAY-TOOLS EXCEPTION WHILE INITIALIZATION"
)