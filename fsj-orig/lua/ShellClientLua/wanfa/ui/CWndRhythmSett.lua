--region CWndRhythmSett.lua
--Date 2017.08.24

function CWndRhythmSett:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType );
end

function CWndRhythmSett:OnCreated()
	self.m_Btncontinue = self:GetDlgChild( "btn_jixu" );
	self.m_Btncontinue:AddActionListener( "OnContinue", self );
	self.m_listBaseMap = self:GetDlgChild( "list" );
	self.m_pWndRhythmData = CWndRhythmData:new( "gui/cfg/fsj_xianshimoshi_jiezoutongji.gui", self.m_listBaseMap, 0 );
end

function CWndRhythmSett:OnContinue()
	local pScene = g_App:GetScene();
	local pWanfa = pScene:GetWanfa();
	pWanfa:RhythmSettClickCon();
end

function CWndRhythmSett:GetWndRhythmData()
	return self.m_pWndRhythmData;
end

--endregion
