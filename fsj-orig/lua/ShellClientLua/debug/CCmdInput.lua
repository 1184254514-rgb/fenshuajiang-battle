--region CCmdInput.lua
--Date 2015-12-24

function CCmdInput:Ctor()
	CGWnd.Ctor( self );
	self.m_nID = 1;
	self.m_nCur = 1;
	self.m_listHistory = {}
end

function CCmdInput:OnCreated()
	self:AddCloseAction();	
	self.m_Input = self:GetDlgChild( "W_text" );		
	self.m_Input:AddEventListener( GM_WM_EDIT_RETURN, "OnInputEntered", self );
	self.m_Input:AddEventListener( WM_KEYUP, "OnKeydown", self );
	self:GetDlgChild( "B_ok" ):AddActionListener( "OnInputEntered", self );			
	self:GetDlgChild( "B_left" ):AddActionListener( "OnPreMsg", self );			
	self:GetDlgChild( "B_right" ):AddActionListener( "OnNextMsg", self );
end

function CCmdInput:OnInputEntered( event )
	local sInputText = self.m_Input:GetWndText();
	if sInputText == "" or sInputText == nil then
		return;
	end

	self.m_listHistory[self.m_nID] = sInputText;
	self.m_nID = self.m_nID + 1;
	self.m_nCur = self.m_nID;
	self.m_Input:SetWndText( "" );
    g_App.m_CmdMgr:CheckSpecialCmd( sInputText );
end
		
function CCmdInput:OnKeydown( event )
	if( event.m_wParam == VK_UP ) then
		if self.m_nCur > 1 and self.m_listHistory[self.m_nCur - 1] ~= nil then
			self.m_nCur = self.m_nCur - 1;
		end
	elseif( event.m_wParam == VK_DOWN ) then
		if self.m_nCur < self.m_nID and self.m_listHistory[self.m_nCur + 1] ~= nil then
			self.m_nCur = self.m_nCur + 1;
		end
	else
		return;
	end
	
	self.m_Input:SetWndText( self.m_listHistory[self.m_nCur] );
end
		
function CCmdInput:OnPreMsg( event )
	self:OnKeydown( { m_wParam = VK_UP } )
end
		
function CCmdInput:OnNextMsg( event )
	self:OnKeydown( { m_wParam = VK_DOWN } )
end

--endregion
