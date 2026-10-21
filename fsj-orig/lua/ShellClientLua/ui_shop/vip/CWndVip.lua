--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

s_vip_prize_count = 4;
function CWndVip:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndVip:OnCreated()
	self.m_pWndList = self:GetDlgChild( "list" );

	self.m_pWndChargeVip = CWndChargeVip:new( "gui/cfg/fsj_huiyuan_chongzhi.gui", self, 1 );
	self.m_pWndVipDesc = CWndVipDesc:new( "gui/cfg/fsj_huiyuan_xufei.gui", self, 1 );

	self:AddCloseAction( "close" );

	self:SwitchWnd( self.m_bVipDesc );

	g_App.m_EventDispatcher:AddEventListener( "LoginSucc", "UpdateVipTime", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.VipEndTime", "AnswerVipEndTime", self );
end

function CWndVip:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "LoginSucc", "UpdateVipTime", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.VipEndTime", "AnswerVipEndTime", self );
end

function CWndVip:IsDispatchPlayerDBEvent( EventName )
	if EventName ~= "m_CharBaseData.VipEndTime" 
		and not self:IsShow() then
		return false;
	end
	return true;
end

function CWndVip:UpdateVipTime()
	self.m_nVipGetTime = g_App:GetMainPlayerData().m_CharBaseData:GetVipGetTime();
	self.m_nVipEndTime = g_App:GetMainPlayerData().m_CharBaseData:GetVipEndTime();
end

function CWndVip:AnswerVipEndTime()
	if not g_App:GetMainPlayerData():IsVip() then
		return;
	end
	
	g_App:GetGameStart():OpenVipWnd();
	
	local szEffect = "fx/cfg/huiyuan_xufei.eft";
	if self.m_nVipGetTime == 0 then
		szEffect = "fx/cfg/huiyuan_jinsheng.eft";
	end
	self.m_pWndVipDesc:PlayerEffect( szEffect );
	self:UpdateVipTime();
end

function CWndVip:SwitchWnd( bVipDesc )
	self.m_bVipDesc = bVipDesc;
	if not self:IsCreated() then
		return;
	end
	
	if not g_App:GetMainPlayerData():IsVip() then
		self.m_bVipDesc = false;
	end

	self.m_pWndVipDesc:ShowWnd( self.m_bVipDesc );
	self.m_pWndChargeVip:ShowWnd( not self.m_bVipDesc );
end

function CWndVip:PlayerEffect( bFirst )
	self.m_pWndVipDesc:PlayerEffect( bFirst );
end

--endregion
