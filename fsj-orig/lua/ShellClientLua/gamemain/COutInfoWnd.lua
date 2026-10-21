--region COutInfoWnd.lua
--Date 2017.09.15
--出局信息提示

function COutInfoWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function COutInfoWnd:OnCreated()
	self.m_tblWndInfo = {};
	for i = 1, 3 do 
		self.m_tblWndInfo[i] = self:GetDlgChild( "chuju_" .. i );
	end
	self.m_tick = CTick:new( "OnTick", self );
end

function COutInfoWnd:ShowInfo( nColorID )
	print( "------", nColorID );
	local nIndex = 0;
	if nColorID == 1 then
		nIndex = 1;
	elseif nColorID == 3 then
		nIndex = 3;
	elseif nColorID == 7 then
		nIndex = 2;
	end
	for i = 1, 3 do 
		self.m_tblWndInfo[i]:ShowWnd( i == nIndex )
	end
	self:GetParent().m_pWndRank2.m_bOut = true;
	self:ShowWnd( true );
end

function COutInfoWnd:OnWndShow( bShow )
	if bShow then
		self.m_tick:Start( 3000 );
	else
		self.m_tick:Stop();
	end
end

function COutInfoWnd:OnTick()
	self:ShowWnd( false );
end

--endregion
