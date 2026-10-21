--region CGEdit.lua
--Date 2017-03-01
--文本编辑框

function CGEdit:OnFocus( bFocus )
	if self.m_bClearDefaultText then
		if bFocus then
			if not self.m_szDefStr then
				self.m_szDefStr = self:GetWndText();
			end

			if self.m_bEmptyInput ~= false then
				self:SetWndText( "" );
			end
		else
			if self:GetWndText() == "" then
				self:SetWndText( self.m_szDefStr );
			end
			if self.OnEditCompleted then
				self:OnEditCompleted();
			end
		end
	else
		if bFocus then

		else
			if self.OnEditCompleted then
				self:OnEditCompleted();
			end
		end
	end
end

function CGEdit:OnWndShow( bShow )
	if not self.m_bClearDefaultText then
		return;
	end

	if bShow then
		self:AddEventListener( WM_CHAR, "OnCharInput", self );
	else
		self:RemoveEventListener( WM_CHAR, "OnCharInput", self );
	end
end

function CGEdit:OnCharInput()
	local szText = self:GetWndText();
	self.m_bEmptyInput = szText == "" or not szText;
end

function CGEdit:SetClearDefaultTextStyle()
	self.m_bClearDefaultText = true;
end
--endregion
