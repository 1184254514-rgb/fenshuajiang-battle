--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndSpecialOffer:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CWndSpecialOffer:OnCreated()
	CGWnd.OnCreated( self );

	self.m_pBtnOK = self:GetDlgChild( "btn_ok" );

	self.m_pBtnOK:AddClickListener( "OnClick", self );
	self:AddCloseAction();
end

function CWndSpecialOffer:OnDestroy()
	CGWnd.OnDestroy( self );
end

function CWndSpecialOffer:OnClick()
	local nRechargeID = 1000;

	if g_tblTabFile.yunyinglibao[nRechargeID].bRes == 0 then
		g_App:Recharge( nRechargeID );
	else
		local NetMsg = CSpecialOffer:new();
		g_App:SendShellMsg( NetMsg );
	end
end

--endregion
