-- not shipped in the 1.3.3 package (downloaded from the server in the original); rich-icon table left empty
g_data_iconconfig = g_data_iconconfig or {}
if OnTableLoadFinished ~= nil then
	OnTableLoadFinished( "iconconfig", g_data_iconconfig )
end
