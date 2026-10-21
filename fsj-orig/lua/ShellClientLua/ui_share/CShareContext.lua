--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

s_share_type_image = 0;
s_share_type_page = 1;

s_channel_QQ = "QQ";
s_channel_QQSpace = "QQSpace";
s_channel_WeiXin = "WeiXin";
s_channel_WeiXinTimeline = "WeiXinTimeline";

function CShareContext:Ctor( szShareSrcName )
	self.m_szShareSrcName = szShareSrcName;
end

function CShareContext:SetImageData( szImgUrl )
	self.m_nShareType = s_share_type_image;
	self.m_szImgUrl		= szImgUrl;
end

function CShareContext:SetPageData( szTitle, szWXTimelineTitle, szContent, szImgUrl, szPageUrl )
	self.m_nShareType			= s_share_type_page;
	self.m_szTitle				= szTitle;
	self.m_szWXTimelineTitle	= szWXTimelineTitle;
	self.m_szContent			= szContent;
	self.m_szImgUrl				= szImgUrl;
	self.m_szPageUrl			= szPageUrl;
end

function CShareContext:GetShareMsg( szChannel )
	local tblJson = 
	{
		["strChannel"] = szChannel,
	};
	if self.m_nShareType == s_share_type_image then
		tblJson["strType"] = "Image";
		tblJson["strImgUrl"] = self.m_szImgUrl;
	elseif self.m_nShareType == s_share_type_page then
		tblJson["strType"] = "Page";
		tblJson["strTitile"] = self.m_szTitle;
		if szChannel == s_channel_WeiXinTimeline then
			tblJson["strTitile"] = self.m_szWXTimelineTitle;
		end
		tblJson["strContent"] = self.m_szContent;
		tblJson["strImgUrl"] = self.m_szImgUrl;
		tblJson["strPageUrl"] = self.m_szPageUrl;
	end
	return json.encode( tblJson );
end

function CShareContext:ShareQQ()
	g_App.m_szShareSrcName = self.m_szShareSrcName;
	g_App:SendSDKCmd( eLoginAndPayCmd_Share, self:GetShareMsg(s_channel_QQ) );
end

function CShareContext:ShareQQSpace()
	g_App.m_szShareSrcName = self.m_szShareSrcName;
	g_App:SendSDKCmd( eLoginAndPayCmd_Share, self:GetShareMsg(s_channel_QQSpace) );
end

function CShareContext:ShareWeiXin()
	g_App.m_szShareSrcName = self.m_szShareSrcName;
	g_App:SendSDKCmd( eLoginAndPayCmd_Share, self:GetShareMsg(s_channel_WeiXin) );
end

function CShareContext:ShareWeiXinTimeline()
	g_App:SendSDKCmd( eLoginAndPayCmd_Share, self:GetShareMsg(s_channel_WeiXinTimeline) );
end

--endregion
