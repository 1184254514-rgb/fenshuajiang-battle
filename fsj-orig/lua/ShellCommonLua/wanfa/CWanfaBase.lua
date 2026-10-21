--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--活动玩法的实现类
local s_AllShowClass = 
{
};

function CreateWanfa( nRoomType, pScene )
	local Class = s_AllShowClass[nRoomType] or CWanfaBase;
	return Class:new( pScene );
end

function RegisterWanfaClass( nRoomType, Class )
	assert( not s_AllShowClass[nRoomType] );
	s_AllShowClass[nRoomType] = Class;
end

function CWanfaBase:Ctor( pScene )
	self.m_pScene = pScene;
	self.m_EventDispatcher = CEventDispatcher:new();
end

--endregion
