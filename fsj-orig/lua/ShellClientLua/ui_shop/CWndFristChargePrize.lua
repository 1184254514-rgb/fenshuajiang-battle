--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndFristChargePrize:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndFristChargePrize:OnCreated()
	self.m_pWndCharges = self:GetDlgChild( "bg.chongzhiqian" );
	self.m_pWndPrizes = self:GetDlgChild( "bg.chongzhihou" );
	self.m_pBtnGetPrize = self.m_pWndPrizes:GetDlgChild( "btn_ok" );
	self.m_pBtnDiamond = self.m_pWndCharges:GetDlgChild( "btn_2" );
	self.m_pBtnVip = self.m_pWndCharges:GetDlgChild( "btn_1" );
	self.m_tblItems = {};
	for i = 1, 4 do
		local pWnd = self:GetDlgChild( "bg.wupin" .. i );
		local tblWnd = 
		{
			["pWndIcon"] = CRichIconWnd:new( pWnd, "suipian" ),
			["pWndNum"] = pWnd:GetDlgChild( "shuliang" ),
		};
		table.insert( self.m_tblItems, tblWnd );
	end
	
	self:AddEventListener( GM_WM_MOUSECLICK, "OnClose", self );
	self.m_pBtnGetPrize:AddClickListener( "OnGetPrize", self );
	self.m_pBtnVip:AddClickListener( "OpenVipWnd", g_App:GetGameStart() );
	self.m_pBtnDiamond:AddClickListener( "OpenDiamondShop", g_App:GetGameStart() );

	g_App:GetMainPlayerData():AddEventListener( "m_FirstEvent", "UpdateWnd", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.RechargeID", "UpdateWnd", self );

	self:UpdateWnd();
end

function CWndFristChargePrize:OnDestroy()
	g_App:GetMainPlayerData():RemoveEventListener( "m_FirstEvent", "UpdateWnd", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.RechargeID", "UpdateWnd", self );
end

function CWndFristChargePrize:OnWndShow( bShow )
	if not bShow then
		return;
	end

	self:UpdateWnd();
end

function CWndFristChargePrize:UpdateWnd()
	local nCurPos = 1;
	local nRowCount = g_tblTabFile.firstchargeprize.nRowCount - 1;
	for i = 1, nRowCount do
		local nValid = CTableConfigMgr:Inst():GetConfigString( "firstchargeprize", i, "nValid" );
		local nShow = CTableConfigMgr:Inst():GetConfigString( "firstchargeprize", i, "nShow" );
		if tonumber( nValid ) ~= 0 and tonumber( nShow ) ~= 0 then
			local nType = CTableConfigMgr:Inst():GetConfigString( "firstchargeprize", i, "nType" );
			local nIndex = CTableConfigMgr:Inst():GetConfigString( "firstchargeprize", i, "nIndex" );
			local nCount = CTableConfigMgr:Inst():GetConfigString( "firstchargeprize", i, "nCount" );
			local nIconID = CPropBaseConfigMgr:Inst():GetConfig( tonumber( nType ), tonumber( nIndex ) ).nIconID;

			local tblWnd = self.m_tblItems[nCurPos];
			tblWnd.pWndIcon:SetIconID( nIconID );
			tblWnd.pWndNum:SetWndText( tostring( nCount ) );
			nCurPos = nCurPos + 1;
		end
	end

	local bGet = g_App:GetFirstEvent( eFE_FirstChargePrize );
	local bCharge = g_App:GetMainPlayerData().m_CharBaseData:GetRechargeID() ~= 0;
	self.m_pWndCharges:ShowWnd( not bCharge and not bGet );
	self.m_pWndPrizes:ShowWnd( bCharge and not bGet );
end

function CWndFristChargePrize:OnGetPrize()
	local NetMsg = CGetFirstChargePrize:new();
	g_App:SendShellMsg( NetMsg );
end

--endregion
