--region CSkillDevelopConfLua.lua
--Date	2018/1/8
--此文件由[BabeLua]插件自动生成
CSkillDevelopConfLua = class();

function CSkillDevelopConfLua:Ctor()
	
end

function CSkillDevelopConfLua:Inst()
	if not self.m_Inst then
		self.m_Inst = CSkillDevelopConfLua:new();
	end

	return self.m_Inst;
end

function CSkillDevelopConfLua:SetIcon( pIcon, nSkillID )
    local cfgItem = g_tblTabFile.skill[nSkillID];
    if cfgItem == nil then
        return;
    end
    
	local rtImg = CFRect:new( cfgItem.nIconX, cfgItem.nIconY, cfgItem.nIconWidth, cfgItem.nIconHeight );
    local rtWnd = CFRect:new();
	rtWnd:right( pIcon:GetWndWidth() );
	rtWnd:bottom( pIcon:GetWndHeight() );

    pIcon:RestoreImageFromCreateParam();
    for i = eST_ENABLE, eST_UNCHECK_CLICKDOWN, 1 do
        pIcon:AddImage( GSM_BS_BK, i, pIcon:GetImageCount( GSM_BS_BK, i ), g_App:GetDataPath()..cfgItem.sTex, 
		    rtImg, rtWnd, 0xffffffff, LOCK_ALL, IDF_ENABLE_ALPHA_BLEND, -1, -1, 0, 1, 0 );
    end
end

function CSkillDevelopConfLua:SetName( pWndText, nSkillID )
	local cfgItem = self.cfg[nSkillID];
    if cfgItem == nil then
        return "";
    end
	pWndText:SetWndText( g_Dictionary:GetValueByString( cfgItem.dName ) );
end


--endregion
