--region CIconManager.lua
--Date 2016/1/9

function CIconManager:Ctor()
end

function CIconManager:Instance()
    if self.m_instance == nil then
       self.m_instance = self:new()
    end
    return self.m_instance
end

function CIconManager:SetIconToRichButton( wndTarget, nIconID, bNeedClick, fBorder, bClearBKImage )
    if wndTarget == nil then
        return;
    end

    if nIconID == nil or nIconID <= 0 then
        return;
    end
	
	local funSetIcon = {};
	funSetIcon.fun = function()	
		wndTarget:RemoveEventListener( WM_CREATE, funSetIcon.fun );
		if not bClearBKImage then
			wndTarget:RestoreImageFromCreateParam();
		else for i = eST_ENABLE, eST_CLICKDOWN do
			wndTarget:SetImageList( GSM_BS_BK, i, nil, 0, -1, 0, -1 );
		end end
		
		local szTextureName = ""
		local rtTexture = nil;
		local nSaturation = 1;
		local nHueTransform = 0;
		local nRichIcon = -1;
		local nRichIconX = 0;
		local nRichIconY = 0;

		local IconInfo = g_tblTabFile.iconconfig[nIconID];
		if IconInfo then
			nTextureIndex = IconInfo.nRawIcon;
			nHueTransform = -(IconInfo.nIconColor / 180);
			nSaturation = 1 + IconInfo.nSaturation / 100;
			nRichIcon = IconInfo.nComicon;
			nRichIconX = IconInfo.nComiconX;
			nRichIconY = IconInfo.nComiconY;

			rtTexture = CFRect:new();
			rtTexture:left( g_tblTabFile.iconconfig[nIconID].nLeft );
			rtTexture:right( g_tblTabFile.iconconfig[nIconID].nRight );
			rtTexture:top( g_tblTabFile.iconconfig[nIconID].nTop );
			rtTexture:bottom( g_tblTabFile.iconconfig[nIconID].nBottom );
		end
		
		local fWndWidth = wndTarget:GetWndWidth();
		local fWndHeight = wndTarget:GetWndHeight();
		fBorder = fBorder or 0;

		local rtIcon = CFRect:new();
		rtIcon:left( fBorder );
		rtIcon:right( fWndWidth - fBorder );
		rtIcon:top( fBorder );
		rtIcon:bottom( fWndHeight - fBorder );

		local nDrawFlag = BitOr( IDF_ENABLE_ALPHA_BLEND, IDF_ZOOM_WHILE_SCALE );
		if nRichIcon > 0 then
			local xScale = fWndWidth/self.m_nIconBaseSize;
			local yScale = fWndHeight/self.m_nIconBaseSize;
			local RichIconImageList = wndTarget:GetGUI():CreateImageGroupFromIconFrame( nRichIcon, 
				nRichIconX*xScale, nRichIconY*yScale, xScale, yScale, 0xffffffff, LOCK_ZALL, nDrawFlag );
			for i = eST_ENABLE, eST_CLICKDOWN do
				wndTarget:SetImageList( GSM_BS_BK, i, RichIconImageList, 0, 0, 0, -1 );
			end
			RichIconImageList:Release();
		end

		local tblClickColor = { 0xffffffff, 0xffffffff, 0x00505050, 0xffa0a0a0 }
		for i = eST_ENABLE, eST_CLICKDOWN do
			local nMulColor = bNeedClick and tblClickColor[ i - eST_ENABLE + 1 ] or 0xffffffff;
			wndTarget:AddImage( GSM_BS_BK, i, wndTarget:GetImageCount( GSM_BS_BK, i ), g_tblTabFile.iconconfig[nIconID].sTextureFileName, rtTexture, 
				rtIcon, nMulColor, LOCK_ALL, nDrawFlag, -1, -1, 0, nSaturation, nHueTransform );
		end
	end

	if wndTarget:IsCreated() then
		funSetIcon.fun();
	else
		wndTarget:AddEventListener( WM_CREATE, funSetIcon.fun );
	end

end

function CIconManager:LoadIconConfig()
   --读取lua文件iconconfig.lua
   for k,v in pairs( g_data_iconconfig ) do
        local paramTab = CIconManager.SubParam( g_data_iconconfig[k].sFrameRects,";" );
        local buffer = CBufferStream:new()
        for i,v in pairs(paramTab) do
            buffer:WriteFloat( paramTab[i] );
        end
        g_App:GetGUIMgr():AddRichIcon( k, g_data_iconconfig[k].sFileName,
            buffer, 1, g_data_iconconfig[k].nScale, "");
   end
end

function CIconManager.SubParam( str, delimiter )
	if str==nil or str=='' or delimiter==nil then
		return nil
	end	
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

--endregion
