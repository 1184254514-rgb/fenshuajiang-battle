--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local eIM_MaxMessageCount = 50;

function CInstantMessageDataMgr:Ctor()
	self.m_IsChatting = false;
	self.m_tblMsgWorld = {}					-- 可直接用于显示的消息列表
	self.m_tblMsgFriend = {};				-- 可直接用于显示的消息列表								
	self.m_nFriendUnreadCount = {};			-- 用户未读消息数
	self.m_nWorldMsgCooldownLeft = -1;
	self.m_tickWorldMsg = CTick:new( "OnWorldMsgTick", self );
	self.m_fileFriendChat = {}
	self.m_tblFriendHistory = {}

	g_App.m_EventDispatcher:AddEventListener( "NewMessageWorld", "OnNewMessageWorld", self );
	g_App.m_EventDispatcher:AddEventListener( "NewMessageFriend", "OnNewMessageFriend", self );
	g_App.m_EventDispatcher:AddEventListener( "LoginSucc", "OnLoginSucc", self );
end

function CInstantMessageDataMgr:Destroy()
	for k, v in pairs( self.m_fileFriendChat ) do
		io.close( v );
	end
	g_App.m_EventDispatcher:RemoveEventListener( "NewMessageWorld", "OnNewMessageWorld", self );
	g_App.m_EventDispatcher:RemoveEventListener( "NewMessageFriend", "OnNewMessageFriend", self );
	g_App.m_EventDispatcher:RemoveEventListener( "LoginSucc", "OnLoginSucc", self );
end

function CInstantMessageDataMgr:OnLoginSucc()
	local szPath = g_App:GetLogPath().."chat/ID_"..g_App:GetAccountID().."/";
	local Buff = CBufferStream:new( 2048 );
	self.m_szCharPath = CPathMgr.ToPhysicalPath( szPath, Buff, 2000 );
	CPathMgr.MakeDirectory( self.m_szCharPath );
end

function CInstantMessageDataMgr:GetWorldMessageContent()
	return self.m_tblMsgWorld;
end

function CInstantMessageDataMgr:GetFriendMessageContent( nAccountID )
	if self.m_tblMsgFriend[nAccountID] == nil then
		self.m_tblMsgFriend[nAccountID] = {};
		self.m_tblFriendHistory[nAccountID] = {}
		local szPath = self.m_szCharPath..nAccountID..".txt";
		local orgFile = io.open( szPath, "r" );
		local tblHistory = {}
		if orgFile then
			io.close( orgFile )
			for line in io.lines( szPath ) do
				if line ~= "" then
					table.insert( tblHistory, line );
				end
			end
		end

		while #tblHistory > 50 do
			local szHistory = table.remove( tblHistory, 1 );
			table.insert( self.m_tblFriendHistory[nAccountID], szHistory );
		end
		
		if nAccountID == eSystemAccountID_CustomerService then
			local NewMsg = {}
			NewMsg.nAccountID = eSystemAccountID_CustomerService;
			NewMsg.nCreateTime = 0;
			NewMsg.szContent = g_App:GetString( "kefutips1" );
			self:UpdateDataFriendContent( nAccountID, NewMsg );
		end

		for k, v in pairs( tblHistory ) do
			local bSelf = string.sub( v, 1, 2 ) == "M:";
			local NewMsg = {}
			NewMsg.nCreateTime = 0;
			NewMsg.nAccountID = bSelf and g_App:GetAccountID() or nAccountID
			NewMsg.szContent = string.sub( v, 3 );
			self:UpdateDataFriendContent( nAccountID, NewMsg );
		end
		self.m_fileFriendChat[nAccountID] = io.open( szPath, "a+" );
	end
	return self.m_tblMsgFriend[nAccountID];
end

function CInstantMessageDataMgr:GetWorldMessageContentLast()
	local tblContent = self.m_tblMsgWorld;
	local nContentCount = #tblContent;
	if nContentCount <= 0 then
		return "";
	end
	
	local FriendMgr = CFriendMgr:Inst();
	local nAccountID = tblContent[nContentCount].nAccountID;
	local CharInfo = FriendMgr:GetCharInfo( nAccountID );
	return CharInfo.szCharName .. ": " .. tblContent[nContentCount].szContent
end

function CInstantMessageDataMgr:GetFriendUnReadCount()
	local nUnReadNum = 0;
	for _, numData in pairs( self.m_nFriendUnreadCount ) do
		nUnReadNum = nUnReadNum + numData;
	end
	return nUnReadNum > 99 and 99 or nUnReadNum;
end

function CInstantMessageDataMgr:GetAccountUnReadCount( nAccountID )
	local nUnReadCount = self.m_nFriendUnreadCount[nAccountID];
	return nUnReadCount == nil and 0 or nUnReadCount;
end

function CInstantMessageDataMgr:ClearAccountUnReadCount( nAccountID )
	self.m_nFriendUnreadCount[nAccountID] = 0;
	local Event = {};
    Event.m_Type = "RefreshIMFriendUnReadWnd";			-- 更新好友列表未读消息数
	Event.m_nAccountID = nAccountID;
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CInstantMessageDataMgr:FilterChar( szContent )
	local nLen = string.len( szContent );
	self.m_FilterBuffer = self.m_FilterBuffer or CBufferStream:new()
	self.m_FilterBuffer:SetPosition( 0 );
	self.m_FilterBuffer:WriteUTFBytes( szContent, nLen + 1 );
	CUSFilter:Inst():Filter( self.m_FilterBuffer, nLen + 1, eFilter_Chat );
	self.m_FilterBuffer:SetPosition( 0 );
	return self.m_FilterBuffer:ReadUTFBytes( nLen );
end

function CInstantMessageDataMgr:OnNewMessageFriend( Event )
	local NewMsg = {}
	NewMsg.nAccountID = Event.m_nAccountID;
	NewMsg.nCreateTime = Event.m_nCreateTime;
	NewMsg.szContent = Event.m_szContent;
	self:UpdateDataFriendContent( Event.m_nAccountID, NewMsg );
end

function CInstantMessageDataMgr:OnNewMessageWorld( Event )
	local NewMsg = {}
	NewMsg.nAccountID = Event.m_nAccountID;
	NewMsg.nCreateTime = Event.m_nCreateTime;
	NewMsg.szContent = self:FilterChar( Event.m_szContent );
	local Content = self:GetWorldMessageContent()
	if #Content > 100 then
		table.remove( Content, 1 )
	end
	table.insert( Content, NewMsg );

	local Event = {};
	Event.m_Type = "RefreshWorldContentWnd";
	Event.m_nAccountID = 0;
	g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CInstantMessageDataMgr:UpdateDataFriendContent( nAccountID, NewMsg )
	local Content = self:GetFriendMessageContent( nAccountID )
	table.insert( Content, NewMsg );
	
	if self.m_fileFriendChat[nAccountID] then
		-- 更新内容
		local Event = {};
		Event.m_Type = "RefreshFriendContentWnd";			
		Event.m_nAccountID = nAccountID;
		g_App.m_EventDispatcher:DispatchEvent( Event );

		local szType = "M:";
		-- 更新好友列表未读消息数
		if nAccountID == NewMsg.nAccountID then
			szType = "T:";
			local nPreUnreadCount = self.m_nFriendUnreadCount[nAccountID] or 0;
			self.m_nFriendUnreadCount[nAccountID] = nPreUnreadCount + 1;
			local Event = {};
			Event.m_Type = "RefreshIMFriendUnReadWnd";
			Event.m_nAccountID = nAccountID;
			g_App.m_EventDispatcher:DispatchEvent( Event );
		end
		self.m_fileFriendChat[nAccountID]:write( szType..NewMsg.szContent.."\n" );
		self.m_fileFriendChat[nAccountID]:flush();
	end
end

function CInstantMessageDataMgr:SendMsg( nTargetID, szContent, Info )
	if not nTargetID then
		g_App:HideMsg(g_App:GetString("meifasongduixiang"));
		return;
	end

	if string.len( szContent ) == 0 then 
		g_App:HideMsg( g_App:GetString("bunengfakongxiaoxi") );
		return;
	end
	
	-- 把自己的消息加到对话里,全服发消息因为禁言关系，需要全部走服务器  
	if nTargetID == eSystemAccountID_WorldMsg then
		if self.m_nWorldMsgCooldownLeft >= 0 then
			return;
		end

		local nCurLadderStar = g_App:GetCurLadderStar()
		if nCurLadderStar < g_tblTabFile.chat.WorldMsgLadderStar then
			g_App:HideMsg( g_App:GetString( "fayanzige" ) );
			return;
		end

		self.m_nWorldMsgCooldownLeft = g_tblTabFile.chat.WorldMsgInterval;
		self.m_tickWorldMsg:Start( 1000 );
		self:OnWorldMsgTick();

		local NetMsg = CSendIMNewMessage:new();
		NetMsg.nTargetId = nTargetID;
		NetMsg.szContent = self:FilterChar( szContent );
		g_App:SendShellMsg( NetMsg );		
	else
		local NewMsg = {}
		NewMsg.nAccountID = g_App:GetAccountID();
		NewMsg.nCreateTime = math.floor( GetNatureTime()/1000 );
		NewMsg.szContent = szContent;
		self:UpdateDataFriendContent( nTargetID, NewMsg );
				
		if nTargetID == eSystemAccountID_CustomerService then
			local NetMsg = CSendMsg2CustomerService:new();
			NetMsg.Info = Info;
			NetMsg.szContent = szContent;
			g_App:SendShellMsg( NetMsg );
		else
			local NetMsg = CSendIMNewMessage:new();
			NetMsg.nTargetId = nTargetID;
			NetMsg.szContent = szContent;
			g_App:SendShellMsg( NetMsg );
		end
	end
end

function CInstantMessageDataMgr:OnWorldMsgTick()
	local szLeftTimeText = nil;
	if self.m_nWorldMsgCooldownLeft >= 0 then
		local szFormat = CStringConfig:Inst():GetString( "fayanlengque" );
		szLeftTimeText = string.format( szFormat, self.m_nWorldMsgCooldownLeft );
	else
		self.m_tickWorldMsg:Stop();
	end
	local Event = {};
	Event.m_Type = "WorldMsgCooldown";
	Event.m_szLeftTimeText = szLeftTimeText;
	g_App.m_EventDispatcher:DispatchEvent( Event );
	self.m_nWorldMsgCooldownLeft = self.m_nWorldMsgCooldownLeft - 1;
end

--endregion
