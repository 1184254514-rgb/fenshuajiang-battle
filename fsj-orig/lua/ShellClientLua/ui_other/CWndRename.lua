--region CWndRename.lua
--Date 2017.9.7
--此文件由[BabeLua]插件自动生成

function CWndRename:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );	
end

function CWndRename:OnCreated()
	self.m_btnClose		= self:GetDlgChild( "close" );
	self.m_wndNewName	= self:GetDlgChild( "name" );
	self.m_btnOK		= self:GetDlgChild( "b_OK" );
	
	self.m_wndNewName:SetMaxStringLength( CHARNAME_BYTE_SIZE );
	
	self.m_btnClose:AddActionListener( "OnClickClose", self );
	self.m_btnOK:AddActionListener( "OnClickOk", self );
	
	self.m_wndNewName:AddEventListener( WM_SETFOCUS, "OnNameChange", self );
	self.m_wndNewName:AddEventListener( WM_KILLFOCUS, "OnNameChange", self );
	self.m_wndNewName:AddEventListener( WM_CHAR, "OnNameSet", self );
end

function CWndRename:OnDestroy()
	CGameMain.OnDestroy( self );
	
	self.m_wndNewName:RemoveEventListener( WM_SETFOCUS, "OnNameChange", self );
	self.m_wndNewName:RemoveEventListener( WM_KILLFOCUS, "OnNameChange", self );
	self.m_wndNewName:RemoveEventListener( WM_CHAR, "OnNameSet", self );
end

function CWndRename:OnWndShow( bShow )
	if not bShow then		
		if not g_App:GetFirstEvent( eFE_Rename ) then
			local NetMsg = CCancelFRRename:new();
			NetMsg.nAccountID = g_App:GetAccountID();
			g_App:SendShellMsg( NetMsg );
		end
		if g_App:GetIniFile():GetInteger( "Setting", "LimitTip", 1 ) == 1 
			and g_App:GetGameScore( eRT_LimitTime ) < CSnakeConstant:Inst():Gettuanzhanjiesuofenshu() then
			g_App:GetGameStart().m_pWndLimitTip:ShowWnd( true );
		else
			g_App:GetGameStart():EnterRoom();
		end
	else
		self.m_wndNewName:SetWndText( g_App:GetNickName() );
	end
end

function CWndRename:OnClickClose()
	self:ShowWnd( false );
end

function CWndRename:OnClickOk()
	local szName = self.m_wndNewName:GetWndText();

	--若玩家未进行修改，那么不发送改名消息，直接隐藏
	if g_App:GetNickName() == szName then
		self:ShowWnd( false );
		return;
	end
	self.m_szCurName = szName;
	g_App:Rename( szName );
end

function CWndRename:OnNameChange()
	if self.m_wndNewName:IsFocus() then
		self.m_wndNewName:SetWndText( "" );
	else
		self.m_wndNewName:SetWndText( self.m_szCurName );		
	end
end

function CWndRename:OnNameSet()
	self.m_szCurName = self.m_wndNewName:GetWndText();
end
--endregion
