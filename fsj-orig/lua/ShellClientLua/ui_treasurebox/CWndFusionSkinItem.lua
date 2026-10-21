--region CWndFusionSkinItem.lua
--Date 2017.11.28
-- "fsj_pifu_yangcheng"
--合成皮肤Item 

local eStarAll = 6; 

function CWndFusionSkinItem:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndFusionSkinItem:OnCreated()
	self.m_BtnUsing				= self:GetDlgChild( "shiyongzhong" );
	self.m_BtnUse				= self:GetDlgChild( "b_shiyong" );
	self.m_BtnPromote			= self:GetDlgChild( "b_shengji" );
	self.m_BtnFusion			= self:GetDlgChild( "b_hecheng" );
	self.m_BtnPreView			= self:GetDlgChild( "b_yulan" );
	self.m_BtnView				= self:GetDlgChild( "b_chakan" );
	self.m_Pro					= self:GetDlgChild( "jindutiao" );
	self.m_ProText				= self:GetDlgChild( "jindutiao.shuzi" );
	self.m_Model				= self:GetDlgChild( "moxing" );
	self.m_TextName				= self:GetDlgChild( "name" );
	self.m_TextLevel			= self:GetDlgChild( "name.lv" );
	self.m_tblStar				= {};
	for i = 1, eStarAll do 
		self.m_tblStar[i]		= self:GetDlgChild( "star.star" .. i );
	end
	self.m_pWndSkill		= self:GetDlgChild( "jineng" );
	self.m_tblSkillWnd = {};
	for i = 1, 5 do
		local SubSkillWnd = CRichIconWnd:new( self.m_pWndSkill, i );
		if SubSkillWnd then
			table.insert( self.m_tblSkillWnd, SubSkillWnd );
		end
	end

	self.m_BtnUsing:ShowWnd( false );
	self.m_BtnUse:ShowWnd( false );
	self.m_BtnPromote:ShowWnd( false );
	self.m_BtnFusion:ShowWnd( false );
	self.m_BtnPreView:ShowWnd( false );
	self.m_BtnView:ShowWnd( false );

	self.m_BtnUse:AddActionListener( "OnClickUSe", self );
	self.m_BtnPromote:AddActionListener( "OnClickPromote", self );
	self.m_BtnFusion:AddActionListener( "OnClickFusion", self );
	self.m_BtnPreView:AddActionListener( "OnClickPreView", self );
	self.m_BtnView:AddActionListener( "OnClickView", self );
--	self.m_Model:AddEventListener( GM_WM_MOUSECLICK, "OnShowModel", self );

	self.m_pWndFusion			= CWndFusion:new( "gui/cfg/fsj_pifu_hecheng.gui", self:GetParent():GetParent(), 1);
	self.m_Pro:SetRange( 100 );
end

function CWndFusionSkinItem:OnClickPreView()
	self.m_pWndFusion:SetData( self.m_nIndex );
end

function CWndFusionSkinItem:OnClickView()
	self.m_pWndFusion:SetData( self.m_nIndex );
end

function CWndFusionSkinItem:OnClickUSe()
	local NetMsg = CUsingSkin:new();
	NetMsg.nSkinID = self.m_nShowFusionID;
	g_App:SendShellMsg( NetMsg ); 
end

function CWndFusionSkinItem:OnClickPromote()
	local nIDToFusion = self.m_nShowFusionID + 1;
	self.m_pWndFusion:SetPromotedata( nIDToFusion, self.m_nIndex );
end

function CWndFusionSkinItem:OnClickFusion()
	local nIDToFusion = math.floor( self.m_nShowFusionID/10 ) * 10 + 1;
	self.m_pWndFusion:SetData( self.m_nIndex );	
end

function CWndFusionSkinItem:OnShowModel()
end

function CWndFusionSkinItem:SetDataByIndex( nIndex )
	local tbl = {};
	for i = 1, g_tblTabFile.fusion.nRowCount do
		local nSort = CTableConfigMgr:Inst():GetConfigNumber( "fusion", i, "nSort" )
		local nID = CTableConfigMgr:Inst():GetConfigNumber( "fusion", i, "nID" )
		if nSort == nIndex then
			table.insert( tbl, nID );
		end
	end
	
	self.nMin = tbl[1];
	self.nMax = tbl[table.count( tbl )];
	self.m_nIndex = nIndex;
	self.m_nOwnedFusionID = self:IsOwned();
	self.m_nShowFusionID = self.m_nOwnedFusionID or self.nMin;
	if self.m_nOwnedFusionID then
		for i = self.nMin, self.nMax do
			if i == g_App:GetMainPlayerData().m_CharBaseData:GetCurEquipID() then
				self.m_nShowFusionID = i;
			end
		end
	end
	
	--显示皮肤技能
	if g_tblTabFile.equip_skill[self.m_nShowFusionID].nPassiveEnable ~= 0 then
		self.m_pWndSkill:ShowWnd( true );
		local nPassiveSkillCount = g_tblTabFile.equip_skill[self.m_nShowFusionID].nPassiveSkillCount;
		for i = 1, #self.m_tblSkillWnd do
			if i <= nPassiveSkillCount then
				self.m_pWndSkill:GetDlgChild( i ):ShowWnd( true );
				local nSkillID = g_tblTabFile.equip_skill[self.m_nShowFusionID]["nPassiveSkill"..(i - 1)];
				self.m_tblSkillWnd[i]:SetIconID( g_tblTabFile.skill[nSkillID].nIconID );
			elseif self.m_pWndSkill:GetDlgChild( i ) then
				self.m_pWndSkill:GetDlgChild( i ):ShowWnd( false );
			end
		end
	else
		self.m_pWndSkill:ShowWnd( false );
	end

	self.m_szName = g_tblTabFile.fusion[self.m_nShowFusionID].dName;
	self.m_szDesc = g_tblTabFile.fusion[self.m_nShowFusionID].dDescription;
	for i = 1, eStarAll do 
		self.m_tblStar[i]:EnableWnd( i <= self.m_nShowFusionID%10 );
	end
	self.m_TextName:SetWndText( self.m_szName );
	self.m_TextLevel:SetWndText( self.m_szDesc );

	if not self.m_nOwnedFusionID then
		self.m_BtnPreView:ShowWnd( true );
	else
		self.m_BtnPreView:ShowWnd( false );
		self.m_BtnFusion:ShowWnd( false );
		if self:IsUsing() then
			self.m_BtnUsing:ShowWnd( true );
			self.m_BtnUse:ShowWnd( false );
		else
			self.m_BtnUsing:ShowWnd( false );
			self.m_BtnUse:ShowWnd( true );
		end
		self.m_BtnPromote:ShowWnd( self.m_nOwnedFusionID ~= self.nMax );
		self.m_BtnView:ShowWnd( self.m_nOwnedFusionID == self.nMax );
	end

	if not self.m_pRenderObject then
		self.m_pRenderObject = g_App:CreateRenderObject();
	end
	self.m_pRenderObject:OnEquipUpdated( self.m_nShowFusionID, 0, true, false );
	if self.m_szEffectAllTime then
		self.m_pRenderObject:DeleteLinkObj( "alltimeeffect" );
	end
	self.m_szEffectAllTime = g_tblTabFile.fusion[self.m_nShowFusionID].szEffectAllTime;
	self.m_pRenderObject:AddFusionSkinEffect( self.m_szEffectAllTime, "fx/loop", "alltimeeffect", false, -1 );


	local pair = SFramePair:new();
	self.m_pRenderObject:SetNodeAni( "stand", nil, pair, eAPT_Loop, 0, 0, 1.0, nil );
	local pViewportRenderer = self.m_Model:GetViewportRenderer();
	pViewportRenderer:AddChild( self.m_pRenderObject );
	local Camera = pViewportRenderer:GetCamera();
	Camera:SetUp( CVector3f:new( 0, 1, 0 ) );
	Camera:SetPos( CVector3f:new( -40, 70, 60 ) );
	Camera:SetDest( CVector3f:new( 0, 25, 0 ) );

	if self.m_nOwnedFusionID then
		if self:IsHighest( self.m_nOwnedFusionID ) then
			self.m_nFusionProID = nil;
		else
			self.m_nFusionProID = self.m_nOwnedFusionID + 1;
		end
	else
		self.m_nFusionProID = self.nMin;
	end

	if self.m_nFusionProID then
		local nTotalCount = 0;
		local nCountHave = 0; 
		for i = 1, 5 do
			local nFragmentID = g_tblTabFile.fusion[self.m_nFusionProID]["nFragment"..i];
			if nFragmentID == 0 then
				break;
			end
			local nFragmentCountNeed = g_tblTabFile.fusion[self.m_nFusionProID]["nCount"..i];
			local nFragmentCountHave = g_App:GetFragmentCount( nFragmentID );
			nFragmentCountHave = nFragmentCountHave < nFragmentCountNeed and nFragmentCountHave or nFragmentCountNeed; 
			nCountHave = nCountHave + nFragmentCountHave;
			nTotalCount = nTotalCount + nFragmentCountNeed;
		end
	
		local nPro = nCountHave/nTotalCount*100 < 100 and nCountHave/nTotalCount*100 or 100;
		local str = string.format( "%d%%", nPro );
		self.m_Pro:SetPos( nPro );
		self.m_ProText:SetWndText( str );
		if nPro == 100 and not self.m_nOwnedFusionID then
			self.m_BtnPreView:ShowWnd( false );
			self.m_BtnFusion:ShowWnd( true );
		end
	else
		self.m_Pro:ShowWnd( false );
	end
end

function CWndFusionSkinItem:OnUpdate()
	if not self.m_nIndex then 
		return 
	end
	self:SetDataByIndex( self.m_nIndex );
end

function CWndFusionSkinItem:IsOwned()
	if ( not self.nMin ) or ( not self.nMax )then
		return nil;
	end
	local PlayerData = g_App:GetMainPlayerData().m_HaveEquip;
	local nOwnedFusionID = nil;
	for j = self.nMin, self.nMax do
		for i = 1, PlayerData:GetDataCount() do
			if PlayerData:GetData( i - 1 ) == j then
				nOwnedFusionID = j;
			end
		end
	end
	return nOwnedFusionID;
end

function CWndFusionSkinItem:IsUsing()
	return g_App:GetMainPlayerData().m_CharBaseData:GetCurEquipID() == self.m_nShowFusionID;
end

function CWndFusionSkinItem:IsHighest( nID )
	return nID == self.nMax;
end



--endregion
