--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndRhythmData:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CWndRhythmData:OnCreated()
	self.m_pWndHistoryNew		= self:GetDlgChild( "bg_lianjijilu.lishi" );
	self.m_pWndWeekNew			= self:GetDlgChild( "bg_lianjijilu.zhou" );
	self.m_pWndTodayNew			= self:GetDlgChild( "bg_lianjijilu.ri" );
	self.m_pBtnGuide			= self:GetDlgChild( "jiaoxue" );
	self.m_pWndMaxCombo			= self:GetDlgChild( "tongji.E_lianjijiangli" );
	self.m_pWndEvaluate			= self:GetDlgChild( "E_pingjia" );
	self.m_pWndEvaluateImage	= self:GetDlgChild( "tongji.pingjia" );
	self.m_pWndTime				= self:GetDlgChild( "tongji.E_time" );
	self.m_tblWndValuation = {};
	for i = 1, eVal_Count do
		self.m_tblWndValuation[i] = self:GetDlgChild( "tongji.E_" .. i );
	end
end

function CWndRhythmData:ShowNewRecord( bNewToday, bNewWeek, bNewHistory )
	self.m_pWndHistoryNew:ShowWnd( false );
	self.m_pWndWeekNew:ShowWnd( false );
	self.m_pWndTodayNew:ShowWnd( false );
	if bNewHistory then
		self.m_pWndHistoryNew:ShowWnd( true );
	elseif bNewWeek then
		self.m_pWndWeekNew:ShowWnd( true );
	elseif bNewToday then
		self.m_pWndTodayNew:ShowWnd( true );
	end
end

function CWndRhythmData:UpdateData( sRhythmData, nRunTime )
	for i = 1, eVal_Count do
		local szShowText = "0.00";
		if sRhythmData.m_nTotle ~= 0 then
			local f = sRhythmData.m_aryCount[i] / sRhythmData.m_nTotle * 100;
			szShowText = string.format( "%0.2f", f );
		end
		self.m_tblWndValuation[i]:SetWndText( szShowText );
	end
	self.m_pWndMaxCombo:SetWndText( tostring( sRhythmData.m_nMaxCombo ) );

	local szEvaluate = CEvaluateConfig:Inst():GetString( sRhythmData.m_nEvaluate );
	self.m_pWndEvaluate:SetWndText( szEvaluate );

	for i = 0, eValEnum_Count - 1 do
		local pWnd = self.m_pWndEvaluateImage:GetDlgChild( tostring( i ) );
		pWnd:ShowWnd( false );
	end
	self.m_pWndEvaluateImage:GetDlgChild( tostring( sRhythmData.m_nEvaluate ) ):ShowWnd( true );
	self.m_pWndTime:SetWndText( string.format( "%02d:%02d:%02d", nRunTime / 3600, nRunTime / 60, nRunTime % 60 ) );
end

----  CWndSettlementGuide
function CWndSettlementGuide:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CWndSettlementGuide:OnCreated()
	self.m_pBtnGuide = self:GetDlgChild( "guanqia" );
	self.m_pBtnVideo = self:GetDlgChild( "zhubo" );

	self:AddCloseAction();
	self.m_pBtnGuide:AddClickListener( "OnClickGuide", self );
	self.m_pBtnVideo:AddClickListener( "OnClickVideo", self );
end

function CWndSettlementGuide:OnClickGuide()
	g_App:SwitchStart();
	CGuideMgr:Inst():Start();
end

function CWndSettlementGuide:OnClickVideo()
	local pGuideVideoWnd = g_App:GetGuideVideoWnd();
	pGuideVideoWnd:PlayVideo();
end

--endregion
