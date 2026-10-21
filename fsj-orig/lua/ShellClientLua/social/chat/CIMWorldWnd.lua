--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local szOtherRes = "gui/cfg/fsj_liaotian_shijie_item1.gui";
local szSelfRes = "gui/cfg/fsj_liaotian_shijie_item2.gui";

function CIMWorldWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CIMWorldWnd:OnCreated()
	self.m_listContent = ClassCast( CContentListPanel, self:GetDlgChild( "list" ) );
	self.m_listContent:InitItemRes( szOtherRes, szSelfRes );
	g_App.m_EventDispatcher:AddEventListener( "RefreshWorldContentWnd", "OnRefreshWnd", self );
end

function CIMWorldWnd:OnDestroy()	
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshWorldContentWnd", "OnRefreshWnd", self );
	CGWnd.OnDestroy( self );
end

function CIMWorldWnd:OnWndShow( bShow )
	self:OnRefreshWnd();
end

function CIMWorldWnd:OnRefreshWnd()
	if not self:IsShow() then
		return;
	end
	self:EnablePreRender( true )
end

function CIMWorldWnd:PreRender( CurTime, nDeltaTime )
	self:EnablePreRender( false )
	local tblContent = g_App:GetInstantMessageDataMgr():GetWorldMessageContent();
	self.m_listContent:UpdateContent( tblContent );
end

function CIMWorldWnd:Close()
	self:ShowWnd( false );
end


--endregion
