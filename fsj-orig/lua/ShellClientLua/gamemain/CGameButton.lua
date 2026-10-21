--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CGameButton:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );

end

function CGameButton:OnCreated()
	self.m_tickPress = CTick:new( "TyroClickTipHelp", self );
	self.m_tickSkillCD = CTick:new( "CheckSkillCD", self );
	self.m_pBtnTop = self:GetDlgChild( "group.shang" );
	self.m_pBtnDown = self:GetDlgChild( "group.xia" );
	self.m_pBtnLeft = self:GetDlgChild( "group.zuo" );
	self.m_pBtnRight = self:GetDlgChild( "group.you" );
	self.m_tblWndPassive = {};
	for i = 1, CSnakeConstant:Inst():GetPassvieSkillNum() do
		local pWndSkillIcon = CRichIconWnd:new( self, "jineng.jineng"..i );
		table.insert( self.m_tblWndPassive, pWndSkillIcon );
	end
	self.m_tblWndEquipPassive = {};
	for i = 1, 5 do
		local pWndSkillIcon = CRichIconWnd:new( self, "pifujineng.jineng"..i );
		if pWndSkillIcon then
			table.insert( self.m_tblWndEquipPassive, pWndSkillIcon );
		end
	end
	self:GetDlgChild( "pifujineng" ):ShowWnd( false );


	self.m_btnWholeScreen = self:GetDlgChild( "quanping" );

	self.m_pBtnTop:AddEventListener( WM_LBUTTONDOWN, "OnButtonDown", self );
	self.m_pBtnDown:AddEventListener( WM_LBUTTONDOWN, "OnButtonDown", self );
	self.m_pBtnLeft:AddEventListener( WM_LBUTTONDOWN, "OnButtonDown", self );
	self.m_pBtnRight:AddEventListener( WM_LBUTTONDOWN, "OnButtonDown", self );

	self.m_pBtnTop:AddEventListener( WM_LBUTTONUP, "OnButtonUp", self );
	self.m_pBtnDown:AddEventListener( WM_LBUTTONUP, "OnButtonUp", self );
	self.m_pBtnLeft:AddEventListener( WM_LBUTTONUP, "OnButtonUp", self );
	self.m_pBtnRight:AddEventListener( WM_LBUTTONUP, "OnButtonUp", self );
	self.m_tblPassiveInfo = {};
	self.m_tblEquipPassiveInfo = {};
	self.m_pBtnSkill = self:GetDlgChild( "B_jineng.tietu" );
	--self.m_pBtnSkill = CRichIconWnd:new( self, "B_jineng.tietu" );	--用CRichIconWnd则需要添加相关资源
	self.m_pBtnSkill:AddEventListener( WM_LBUTTONDOWN, "OnSkillClick", self );
end

function CGameButton:OnDestroy()
	self.m_tickPress:Stop();
	self.m_tickSkillCD:Stop();
end

function CGameButton:OnWndShow( bShow )
	if bShow then
		local pScene = g_App:GetScene();
		self:GetDlgChild( "jineng" ):ShowWnd( pScene and pScene:GetRoomType() ~= eRT_Endless and g_App:CouldUseSkill() );
		if g_App:GetIniFile():GetInteger( "Setting", "BtnConfigChooseSub", 0 ) == 1 then
			self.m_pBtnTop:AddEventListener( WM_LBUTTONDOWN, "OnClickTop", self );
			self.m_pBtnDown:AddEventListener( WM_LBUTTONDOWN, "OnClickDown", self );
			self.m_pBtnLeft:AddEventListener( WM_LBUTTONDOWN, "OnClickLeft", self );
			self.m_pBtnRight:AddEventListener( WM_LBUTTONDOWN, "OnClickRight", self );
			self:GetDlgChild( "group" ):SetFocus();
			self.m_btnWholeScreen:ShowWnd( false );
		else
			self.m_btnWholeScreen:AddEventListener( WM_LBUTTONDOWN, "OnClickWholeScreen", self );
			self.m_btnWholeScreen:ShowAndSetFocus();
		end
	else
		self.m_tblPassiveInfo = {};
		self.m_tblEquipPassiveInfo = {};
		self:GetDlgChild( "pifujineng" ):ShowWnd( false );
		self.m_pBtnTop:RemoveEventListener( WM_LBUTTONDOWN, "OnClickTop", self );
		self.m_pBtnDown:RemoveEventListener( WM_LBUTTONDOWN, "OnClickDown", self );
		self.m_pBtnLeft:RemoveEventListener( WM_LBUTTONDOWN, "OnClickLeft", self );
		self.m_pBtnRight:RemoveEventListener( WM_LBUTTONDOWN, "OnClickRight", self );
		self.m_btnWholeScreen:RemoveEventListener( WM_LBUTTONDOWN, "OnClickWholeScreen", self );
	end
end

function CGameButton:OnClickTop()
	self.m_pBtnTop:AddEffect( "fx/cfg/jiantoudianji_shang.eft", "fx/loop", "up", 0 );
	g_App:GetGameMain():ClickDir( eDF_Up );
end

function CGameButton:OnClickDown()
	self.m_pBtnDown:AddEffect( "fx/cfg/jiantoudianji_xia.eft", "fx/loop", "down", 0 );
	g_App:GetGameMain():ClickDir( eDF_Bottom );
end

function CGameButton:OnClickLeft()
	self.m_pBtnLeft:AddEffect( "fx/cfg/jiantoudianji_zuo.eft", "fx/loop", "left", 0 );
	g_App:GetGameMain():ClickDir( eDF_Left );
end

function CGameButton:OnClickRight()
	self.m_pBtnRight:AddEffect( "fx/cfg/jiantoudianji_you.eft", "fx/loop", "right", 0 );
	g_App:GetGameMain():ClickDir( eDF_Right );
end

function CGameButton:OnButtonDown()
	local nTime = CSnakeConstant:Inst():GetPressAllWay();
	self.m_tickPress:Start( nTime );
end

function CGameButton:OnButtonUp()
	self.m_tickPress:Stop();
end

function CGameButton:OnClickWholeScreen( Event )
	local nDirButtonCenterX = self:GetDlgChild( "group" ):GetGlobalX() + self:GetDlgChild( "group" ):GetWndWidth() / 2;
	local nDirButtonCenterY = self:GetDlgChild( "group" ):GetGlobalY() + self:GetDlgChild( "group" ):GetWndHeight() / 2;
	local nClickX = Event.m_GlobalX;
	local nClickY = Event.m_GlobalY;
	local vDir = CDir:new();
	vDir:Set( CVector2f:new( nClickX - nDirButtonCenterX, nDirButtonCenterY - nClickY ) );
	if 96 <= vDir:uDir() and vDir:uDir() < 160 then
		self:OnClickDown();
	elseif 160 <= vDir:uDir() and vDir:uDir() < 224 then
		self:OnClickLeft();
	elseif 32 <= vDir:uDir() and vDir:uDir() < 96 then
		self:OnClickRight();
	else
		self:OnClickTop();
	end
end

function CGameButton:TyroClickTipHelp()
	self.m_tickPress:Stop();
	g_App:GetGameMain():TyroTipHelp( eMUT_NoLongPress, true );
end

function CGameButton:OnSkillClick()
	local pDirector = g_App:GetDirector();
	if not pDirector then
		return;
	end

	pDirector:UseSkill( self.m_pBtnSkill.m_nSkillID );
	print( "CGameButton:OnSkillClick()" );
end

function CGameButton:PostStartCooling( nCooling )
	self.m_nSkillEndTime = GetGammaTime() + nCooling;
	self.m_tickSkillCD:Start( 500 );
	self.m_pBtnSkill:EnableWnd( false );
end

function CGameButton:CheckSkillCD()
	local nTime = self.m_nSkillEndTime - GetGammaTime();
	if nTime > 0 then
		self.m_pBtnSkill:SetWndText( math.floor( nTime / 1000 ) );
		return;
	end
end

function CGameButton:PostEndCooling()
	if self.m_pBtnSkill:IsEnable() then
		return;
	end
	self.m_tickSkillCD:Stop();
	self.m_pBtnSkill:SetWndText( "" );
	self.m_pBtnSkill:EnableWnd( true );
	self.m_pBtnSkill:AddEffect( "fx/cfg/cf_cd.eft", "fx/loop", "cf_cd", 0 );
end

function CGameButton:RefreshActiveSkill( nSkillID, nLevel )
	local str = nLevel;
	if self.m_pBtnSkill.m_nTopLevel == nLevel then
		str = CStringConfig:Inst():GetString( "levelmax" );
	end
	self:GetDlgChild( "B_jineng.dengji" ):SetWndText( str );
end

function CGameButton:RefreshPassiveSkill( nSkillID, nLevel )
	self:InitPassiveSkill();
	for i = 1, #self.m_tblPassiveInfo do
		if self.m_tblWndPassive[i].tblPassiveSkillInfo.nSkillID == nSkillID then
			local str = nLevel;
			if nLevel == self.m_tblWndPassive[i].tblPassiveSkillInfo.nSkillTopLevel then
				str = CStringConfig:Inst():GetString( "levelmax" );
			end
			self.m_tblWndPassive[i]:GetDlgChild( "dengji" ):SetWndText( str );
		end
	end
end

function CGameButton:RefreshEquipPassiveSkill( nSkillID, nLevel )
	self:InitEquipPassiveSkill();
	for i = 1, #self.m_tblEquipPassiveInfo do
		if self.m_tblWndEquipPassive[i].tblEquipPassiveSkillInfo.nSkillID == nSkillID then
			local str = nLevel;
			if nLevel == self.m_tblWndEquipPassive[i].tblEquipPassiveSkillInfo.nSkillTopLevel then
				str = CStringConfig:Inst():GetString( "levelmax" );
			end
			self.m_tblWndEquipPassive[i]:GetDlgChild( "dengji" ):SetWndText( str );
		end
	end
end

--function CGameButton:InitActiveSkill()
--	self:GetDlgChild( "B_jineng" ):ShowWnd( true );
--	local nActiveID = g_App:GetMainPlayerData().m_CharBaseData:GetSkillID();
--	self.m_pBtnSkill:EnableWnd( true );
--	self.m_pBtnSkill.m_nSkillID = nActiveID;
--	self.m_pBtnSkill:SetIconID( g_tblTabFile.skill[nActiveID].nIconID );
--end

function CGameButton:InitPassiveSkill()
	if  not g_App:CouldUseSkill() then
		self:GetDlgChild( "jineng" ):ShowWnd( false );
		self:GetDlgChild( "pifujineng" ):ShowWnd( false );
		return;
	end
	if #self.m_tblPassiveInfo > 0 then
		return;
	end
	local pIDValue = CBufferStream:new( 100 );
	local pLevelValue = CBufferStream:new( 100 );
	g_App:GetDirector():GetPassiveSkill( pIDValue, pLevelValue );
	self:GetDlgChild( "jineng" ):ShowWnd( true );
	self.m_tblPassiveInfo = {};
	for i = 1, CSnakeConstant:Inst():GetPassvieSkillNum() do
		local nPassiveSkillID = pIDValue:ReadUint16();
		local nPassiveSkillLevel = pLevelValue:ReadUint8();
		local tblPassiveSkillInfo = {};
		tblPassiveSkillInfo.nSkillID = nPassiveSkillID;
		tblPassiveSkillInfo.nSkillTopLevel = nPassiveSkillLevel;
		if nPassiveSkillID ~= 0 then
			table.insert( self.m_tblPassiveInfo, tblPassiveSkillInfo );
		end
	end
	for i = 1, CSnakeConstant:Inst():GetPassvieSkillNum() do
		if i <= #self.m_tblPassiveInfo then
			self.m_tblWndPassive[i].tblPassiveSkillInfo = self.m_tblPassiveInfo[i];
			self.m_tblWndPassive[i]:ShowWnd( true );
			self.m_tblWndPassive[i]:GetDlgChild( "dengji" ):SetWndText( 1 );
			self.m_tblWndPassive[i]:GetDlgChild( "dengji" ):ShowWnd( true );
			self.m_tblWndPassive[i]:SetIconID( g_tblTabFile.skill[self.m_tblPassiveInfo[i].nSkillID].nIconID );
		else
			self.m_tblWndPassive[i]:GetDlgChild( "dengji" ):ShowWnd( false );
		end
	end
end

function CGameButton:InitEquipPassiveSkill()
	if  not g_App:CouldUseSkill() then
		self:GetDlgChild( "jineng" ):ShowWnd( false );
		self:GetDlgChild( "pifujineng" ):ShowWnd( false );
		return;
	end
	if #self.m_tblEquipPassiveInfo > 0 then
		return;
	end
	local nEquipID = g_App:GetDirector():GetEquipID();
	if g_tblTabFile.equip_skill[nEquipID].nPassiveEnable == 0 then
		self:GetDlgChild( "pifujineng" ):ShowWnd( false );
		return;
	end
	local nPassiveSkillCount = g_tblTabFile.equip_skill[nEquipID].nPassiveSkillCount;
	self:GetDlgChild( "pifujineng" ):ShowWnd( true );
	self.m_tblEquipPassiveInfo = {};
	for i = 1, nPassiveSkillCount do
		local nEquipPassiveSkillID = g_tblTabFile.equip_skill[nEquipID]["nPassiveSkill"..(i - 1)];
		local nEquipPassiveSkillLevel = 1;
		local tblEquipPassiveSkillInfo = {};
		tblEquipPassiveSkillInfo.nSkillID = nEquipPassiveSkillID;
		tblEquipPassiveSkillInfo.nSkillTopLevel = nEquipPassiveSkillLevel;
		if nEquipPassiveSkillID ~= 0 then
			table.insert( self.m_tblEquipPassiveInfo, tblEquipPassiveSkillInfo );
		end
	end
	for i = 1, nPassiveSkillCount do
		if i <= #self.m_tblEquipPassiveInfo then
			self.m_tblWndEquipPassive[i].tblEquipPassiveSkillInfo = self.m_tblEquipPassiveInfo[i];
			self.m_tblWndEquipPassive[i]:ShowWnd( true );
			self.m_tblWndEquipPassive[i]:GetDlgChild( "dengji" ):SetWndText( 1 );
			self.m_tblWndEquipPassive[i]:GetDlgChild( "dengji" ):ShowWnd( true );
			self.m_tblWndEquipPassive[i]:SetIconID( g_tblTabFile.skill[self.m_tblEquipPassiveInfo[i].nSkillID].nIconID );
		else
			self.m_tblWndEquipPassive[i]:ShowWnd( false );
			self.m_tblWndEquipPassive[i]:GetDlgChild( "dengji" ):ShowWnd( false );
		end
	end
end
--endregion
