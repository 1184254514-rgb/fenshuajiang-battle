--region CPlayerDBClient.lua
--Date 2016/3/28

function CPlayerDBClient:Ctor( buffer )
	CPlayerDB.Ctor( self, buffer or CBufferStream:new( CPlayerDB:GetSize() ) )

	self.m_nameTable = {};
	for k, v in pairs( self )  do
		if type( k ) == "string" and v.m_nID then
			self.m_nameTable[v.m_nID] = k;
		end
	end
end

function CPlayerDBClient:InitFromCompress( Buffer, nBufferLen, nBlockDataHeadSize )
	self.m_buffer:Clear();
	if not nBlockDataHeadSize then
		nBlockDataHeadSize = CPlayerDB:GetSBlockDataSize();
	end
	local BufferCloned = CBufferStream:new();
	local BufferPos = Buffer:GetPosition();
	local BufferData = self.m_buffer;

	if( nBufferLen ) then
		BufferCloned:WriteBytes( Buffer, BufferPos, nBufferLen );
	end

	BufferCloned:SetPosition( 0 );	
	BufferCloned:Uncompress();
	
	local nBlockCount = BufferCloned:ReadUint8();
	for i = 1, nBlockCount do
		local nIndex = BufferCloned:ReadUint8();
		local nSize = BufferCloned:ReadUint32();
		local BlockData = self[nIndex];
		local nTargetOffset = BlockData.offset2BufferStart + nBlockDataHeadSize;
		BufferCloned:ReadBytes( BufferData, nTargetOffset, nSize );
	end
end

function CPlayerDBClient:UpdateFromServer( Buffer, nBlockIndex, nDiffCount )
	local BlockData = self[nBlockIndex];
	local szName = self.m_nameTable[nBlockIndex];
	local BufferData = self.m_buffer;
	local aryMemberInfo = BlockData.m_aryMemberInfo;
	local nIndex = 1;
	local tblEvent = {};
	local tblEventData = {};
	local tblAryIndex = {};
	for i = 1, nDiffCount do
		local nOffset = Buffer:ReadUint16();
		local nSize = Buffer:ReadUint16();
		local nTargetOffset = BlockData.offset2BufferStart + nOffset;
		Buffer:ReadBytes( BufferData, nTargetOffset, nSize );
		--检查侦听
		local nS1 = nOffset;			--更新数据的起始
		local nE1 = nOffset + nSize;	--更新数据的末尾
		for i = 1, #aryMemberInfo do
			local Info = aryMemberInfo[i];
			local nTypeSize = Info[2];
			for j = 0, Info[4] and Info[4] - 1 or 0 do	--里面是处理数组的
				local nS2 = Info[1] + nTypeSize * j;		--寻找数据的起始
				local nE2 = Info[1] + nTypeSize * (j + 1);				--寻找数据的末尾
				if nE1 <= nS2 then
					break;
				end
				if nS1 < nE2 then
					--有交集,加入派发列表
					if Info[5] then
						local key;
						local DataFromAry = BlockData["Get"..Info[3]]( BlockData, j );
						for _k, funName in pairs( Info[5] ) do
							key = key and key.."+"..DataFromAry[funName]( DataFromAry ) or DataFromAry[funName]( DataFromAry );
						end
						tblEvent[szName.."."..Info[3].."."..key] = 1;
						table.insert( tblEventData, key );
					else
						tblEvent[szName.."."..Info[3]..( Info[4] and "."..j or "" )] = 1;
						table.insert( tblEventData, j );
					end
					table.insert( tblAryIndex, j )
				end
			end
		end
	end

	self:DispatchEvent( self:CreateEvent( szName, self, { BlockData, tblEventData, tblAryIndex } ) );
	print( "CPlayerDBClient DispatchEvent", szName );
	for key, _v1 in pairs( tblEvent ) do
		self:DispatchEvent( self:CreateEvent( key, self, { BlockData } ) );
	end
end

function CPlayerDBClient:DispatchEventToHandler( pHandler, funHandler, Event )
	local bDispatch = true;
	if pHandler.IsDispatchPlayerDBEvent then	
		bDispatch = pHandler:IsDispatchPlayerDBEvent( Event.m_Type )
	elseif pHandler:IsInheritFrom( CGWnd ) then
		bDispatch = pHandler:IsShow()
	end
	if bDispatch then
		funHandler( pHandler, Event );
	end
end

function CPlayerDBClient:DispatchEvent( Event )

	if self.m_mapEventListener == nil then
		return
	end
	local aryHandlers = self.m_mapEventListener[Event.m_Type]
	if aryHandlers == nil then
		return;
	end

	self.m_nDispatchDepth = self.m_nDispatchDepth + 1
	local nMaxIndex = table.maxn( aryHandlers );
	for i = 1, nMaxIndex do
		local HandlerInfo = aryHandlers[i];
		if HandlerInfo then
			if HandlerInfo[2] == nil then
				HandlerInfo[1]( Event )
			elseif type( HandlerInfo[1] ) == "string" then
				self:DispatchEventToHandler( HandlerInfo[2], HandlerInfo[2][HandlerInfo[1]], Event )
			else
				self:DispatchEventToHandler( HandlerInfo[2], HandlerInfo[1], Event )
			end
			if Event.m_StopImmediately then
				return;
			end
		end
	end
	self.m_nDispatchDepth = self.m_nDispatchDepth - 1
end

-----------------------------------------------------------------------
-- 数据操作函数
-----------------------------------------------------------------------

local s_prize_type_world = 0;
local s_prize_type_account = 1;
function CPlayerDBClient:IsPrizeValie( tblPrize )
	local nPrizeID = tblPrize.m_nPrizeID;
	
	local nCurTime = GetNatureTime() / 1000;
	if nCurTime < tblPrize.m_nStartTime or
		nCurTime > tblPrize.m_nEndTime then
		return false;
	end

	if tblPrize.m_nType == s_prize_type_world then
		local nCharCreateTimeStart = tblPrize.m_nCharCreateTimeStart;
		local nCharCreateTimeEnd = tblPrize.m_nCharCreateTimeEnd;
		local nCharCreateTime = self.m_CharBaseData:GetCreateTime();
		if( nCharCreateTime < nCharCreateTimeStart or 
			nCharCreateTime > nCharCreateTimeEnd ) then
			return false;
		end
	elseif tblPrize.m_nType == s_prize_type_account then
		if g_App:GetAccountID() ~= tblPrize.m_nAccountID then
			return false;
		end
	else
		return false;
	end

	for i = 0, self.m_WorldPrizeID:GetDataMaxCount() - 1 do
		local nCurPrizeID = self.m_WorldPrizeID:GetData( i );
		if nCurPrizeID == 0 then
			return true;
		end
		if nCurPrizeID == nPrizeID then
			return false;
		end
	end
	return true;
end

function CPlayerDBClient:IsVip()
	local nCurTime = math.floor( GetNatureTime() / 1000 );
	return nCurTime <= self.m_CharBaseData:GetVipEndTime()
		and nCurTime >= self.m_CharBaseData:GetVipGetTime();
end

local s_Day_Of_Month = 31;
function CPlayerDBClient:IsGetVipPrize()
	if self.m_CharBaseData:GetVipPrizeGetTime() < self.m_CharBaseData:GetVipGetTime() then
		return false;
	end
	
	local nMidTime = math.floor( GetNatureTime() / 1000 ) - self.m_CharBaseData:GetVipGetTime();
	local nMonth = math.floor( nMidTime / eTimeConst_DaySeconds / s_Day_Of_Month );
	local nMonthStartTime = self.m_CharBaseData:GetVipGetTime() + nMonth * s_Day_Of_Month * eTimeConst_DaySeconds;

	if self.m_CharBaseData:GetVipPrizeGetTime() < nMonthStartTime then
		return false;
	else
		return true;
	end
end

--endregion
