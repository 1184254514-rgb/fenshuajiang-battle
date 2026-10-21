--region CWndBeCommend.lua
--Date 2017.10.31
--此文件由[BabeLua]插件自动生成

local REMAINTIME = 1500;	--停滞时间
local MOVETIME = 15;		--移动次数  

function CWndBeCommend:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndBeCommend:OnCreated()
	self.m_tick = CTick:new( "OnHideWnd", self );
	self.m_tblShow = {};
	self.m_fOriginY = self:GetLocalY();
	self.m_nRemainTime = 0;
	self.m_nMoveSpeed = self.m_fOriginY/MOVETIME;
end

function CWndBeCommend:OnDestroy()
	CGWnd.OnDestroy( self );
	self.m_tick:Stop();
end

function CWndBeCommend:ShowInfo( szInfo )
	table.insert( self.m_tblShow, szInfo );
	if not self.m_tick:IsRegisted() then
		self.m_tick:Start( 33 );
	end
end

function CWndBeCommend:OnHideWnd()
	self:ShowWnd( true );
	self:SetWndText( self.m_tblShow[1] );
	self.m_nRemainTime = self.m_nRemainTime + 33;
	if self.m_nRemainTime >= REMAINTIME then
		self:SetLocalY( self:GetLocalY() - self.m_nMoveSpeed );
	end

	if self:GetLocalY() <= 0 then
		table.remove( self.m_tblShow, 1 );
		self:SetLocalY( self.m_fOriginY );
		self.m_nRemainTime = 0;
		self:ShowWnd( false );
	end

	if table.count( self.m_tblShow ) == 0 then
		self.m_tick:Stop();
	end
end


--endregion
