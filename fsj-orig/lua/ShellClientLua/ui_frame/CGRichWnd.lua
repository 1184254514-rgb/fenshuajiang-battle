--region CGRichWnd.lua
--Date 2015/12/23

function CGRichWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGScrollPane.Ctor( self, sResName, ParentWnd, nLoadType )
    self.m_bNeedHandleLink = false;   
	self:AddEventListener( GM_WM_RICH_CLICK_ID, "OnHyperLinkClick", self );
	self:AddClickListener( "OnClickGRichWnd", self );
end
    
function CGRichWnd:OnClickGRichWnd( Event )
	if self ~= Event.m_Target then
		return;
	end

	local nUnitID = self:TestUnitID( Event.x, Event.y );
	if nUnitID then
		return;
	end

	local nLinkID = self.m_pWndContent:GetFirstHyperLinkID();
	if not nLinkID or self.m_pWndContent:GetHyperLinkIDString( 2 ) then
		return;
	end

	g_App.m_CmdMgr:TriggerHyperLink( strLinkID, self, nUnitID );
end
    
function CGRichWnd:OnHyperLinkClick( Event )
	if( Event.m_Target ~= self ) then
		return;
	end

	local nUnitID = math.floor( Event.m_wParam/65536 );
	local nLinkID = nUnitID > 0 and self:GetHyperLinkID( nUnitID ) or 0;
	local strLinkID = nLinkID > 0 and self:GetHyperLinkIDString( nLinkID ) or 0;
	if( strLinkID == nil or strLinkID == "" ) then
		return;
	end

	g_App.m_CmdMgr:TriggerHyperLink( strLinkID, self, nUnitID );
end

--endregion
