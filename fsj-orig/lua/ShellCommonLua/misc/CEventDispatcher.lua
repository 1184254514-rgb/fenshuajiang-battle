--region CEventDispatch.lua
--Date 2015-12-07

function CEventDispatcher:ctor()
	self.m_nDispatchDepth = 0;
end

--创建一个事件
function CEventDispatcher:CreateEvent( Type, Target, Param )
	return { m_Type = Type, m_Target = Target, m_Param = Param }; 
end

--移除所有监听
function CEventDispatcher:RemoveAllEventListener( Type )
	if self.m_mapEventListener == nil then
		return;
	end
	if Type then
		self.m_mapEventListener[Type] = nil;
	else
		self.m_mapEventListener = nil;
	end
end

--添加监听
function CEventDispatcher:AddEventListener( Type, funHandler, pHandler )
	if funHandler == nil then
		return;
	end

	if( type( funHandler ) == "string" and 
		( pHandler == nil or pHandler[funHandler] == nil ) ) then
		return
	end

	if self.m_mapEventListener == nil then
		self.m_mapEventListener = {}
	end

	if self.m_mapEventListener[Type] == nil then
		self.m_mapEventListener[Type] = {}
	end

	local aryHandlers = self.m_mapEventListener[Type];
	local nMaxIndex = table.maxn( aryHandlers )
	for i = 1, nMaxIndex + 1 do
		if aryHandlers[i] and 
			aryHandlers[i][1] == funHandler and
			aryHandlers[i][2] == pHandler then
			return true;
		end
		if aryHandlers[i] == nil then
			aryHandlers[i] = { funHandler, pHandler }
			return true;
		end
	end
end

--移除指定监听
function CEventDispatcher:RemoveEventListener( Type, funHandler, pHandler )
	if funHandler == nil then
		return;
	end

	if self.m_mapEventListener == nil then
		return
	end

	if self.m_mapEventListener[Type] == nil then
		return
	end

	local aryHandlers = self.m_mapEventListener[Type]
	local nMaxIndex = table.maxn( aryHandlers )
	for i = 1, nMaxIndex do
		if aryHandlers[i] and 
		aryHandlers[i][1] == funHandler and
		aryHandlers[i][2] == pHandler then
			if i ~= nMaxIndex and ( self.m_nDispatchDepth or 0 ) == 0 then
				aryHandlers[i] = aryHandlers[nMaxIndex]
				i = nMaxIndex
			end
			aryHandlers[i] = nil
			if nMaxIndex == 1 then
				self.m_mapEventListener[Type] = nil
			end
			return
		end
	end
end

--监听是否存在
function CEventDispatcher:HasEventListener( Type, funHandler, pHandler )
	if self.m_mapEventListener == nil then
		return false;
	end

	if self.m_mapEventListener[Type] == nil then
		return false;
	end
	
	local aryHandlers = self.m_mapEventListener[Type]
	local nMaxIndex = table.maxn( aryHandlers )
	if funHandler == nil then
		return nMaxIndex >= 1;
	else
		for i = 1, nMaxIndex do
			if aryHandlers[i][1] == funHandler and
				aryHandlers[i][2] == pHandler then
				return true;
			end
		end
		return false;
	end
end

--派发事件
function CEventDispatcher:DispatchEvent( Event )

	if self.m_mapEventListener == nil then
		return
	end
	local aryHandlers = self.m_mapEventListener[Event.m_Type]
	if aryHandlers == nil then
		return;
	end

	self.m_nDispatchDepth = ( self.m_nDispatchDepth or 0 ) + 1
	local nMaxIndex = table.maxn( aryHandlers );
	for i = 1, nMaxIndex do
		local HandlerInfo = aryHandlers[i];
		if HandlerInfo then
			if HandlerInfo[2] == nil then
				HandlerInfo[1]( Event )
			elseif type( HandlerInfo[1] ) == "string" then
				HandlerInfo[2][HandlerInfo[1]]( HandlerInfo[2], Event )
			else
				HandlerInfo[1]( HandlerInfo[2], Event )
			end
			if Event.m_StopImmediately then
				return;
			end
		end
	end
	self.m_nDispatchDepth = self.m_nDispatchDepth - 1
end

--endregion
