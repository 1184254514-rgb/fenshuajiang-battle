--region CGameStartMisc.lua
--Date	2018.3.7
--此文件由[BabeLua]插件自动生成

function CNewSeasonComing:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CNewSeasonComing:OnCreated()
	self.m_pWndLeftTime = self:GetDlgChild( "neirong" );
	self.m_pBtnOK = self:GetDlgChild( "btn_ok" );
	self.m_pBtnOK:AddActionListener( "OnClose", self );
end

function CNewSeasonComing:ShowLeftTime()
	local bShow, nDis = self:GetNewSeasonLeftDays();
	local nLocalTime = GetLocalTime();
	local nLogOutTime = g_App:GetMainPlayerData().m_CharBaseData:GetLogoutTime() * 1000;
	local bFirstLogin = nLocalTime - nLogOutTime > eTimeConst_DayMiSeconds;
	if bShow and bFirstLogin then
		local Str = string.format( g_App:GetString( "saijidaojishi" ), nDis );
		self.m_pWndLeftTime:SetWndText( Str );
		self:ShowWnd( true );
	end
end

function CNewSeasonComing:GetNewSeasonLeftDays()
	local nLocalTime = GetLocalTime();
	local sTime = GetFormatTimeSTMFromMillisecond( nLocalTime );
	local nCurDayOfMonth = sTime:m_nDayOfMonth();
	local nCurMonthDays = GetCurMonthDays( nLocalTime );
	local nDis = nCurMonthDays - nCurDayOfMonth + 1;
	local nShowNum = g_tblTabFile.star_left_days.nRowCount;
	local bShow = false;
	for i = 1, nShowNum do
		if nDis == g_tblTabFile.star_left_days:GetRow( i ).nShowDays then
			bShow = true;
			break;
		end
	end
	return bShow, nDis;
end

function CNewSeasonComing:OnClose()
	self:ShowWnd( false );
end
--endregion
