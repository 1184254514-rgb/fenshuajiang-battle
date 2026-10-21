--region CGameScene.lua
--Date 2017-08-05

function CGameScene:Ctor()
	self.m_tblPlayerInfo = {};
	self.m_pWanfa = nil;
end

function CGameScene:GetRoomType()
	return self.m_nRoomType;
end

local CGameScene_Create = CGameScene.Create;
function CGameScene:Create( pRenderer, nRoomType, nAIUseSkill )
	self.m_pWanfa = CreateWanfa( nRoomType, self );
	self.m_nRoomType = nRoomType;
	self.m_nAIUseSkill = nAIUseSkill;
	CGameScene_Create( self, pRenderer, nRoomType, nAIUseSkill );
end

local CGameScene_OnSceneCreated = CGameScene.OnSceneCreated;
function CGameScene:OnSceneCreated()
	CGameScene_OnSceneCreated( self );

	local Event = {};
    Event.m_Type = "OnSceneCreated";
	self.m_pWanfa.m_EventDispatcher:DispatchEvent( Event );
end

local CGameScene_OnSceneDestroy = CGameScene.OnSceneDestroy;
function CGameScene:OnSceneDestroy()
	local Event = {};
    Event.m_Type = "OnSceneDestroy";
	self.m_pWanfa.m_EventDispatcher:DispatchEvent( Event );

	CGameScene_OnSceneDestroy( self );
end

local CGameScene_InsertObject = CGameScene.InsertObject;
function CGameScene:InsertObject( pObject, posPixel )
	CGameScene_InsertObject( self, pObject, posPixel );

	local Event = {};
    Event.m_Type = "OnInsertObject";
	Event.m_Object = pObject;
	Event.m_posPixel = posPixel;
	self.m_pWanfa.m_EventDispatcher:DispatchEvent( Event );
end

local CGameScene_RemoveObject = CGameScene.RemoveObject;
function CGameScene:RemoveObject( pObject )
	local Event = {};
    Event.m_Type = "OnRemoveObject";
	Event.m_Object = pObject;
	Event.m_posPixel = posPixel;
	self.m_pWanfa.m_EventDispatcher:DispatchEvent( Event );
	
	CGameScene_RemoveObject( self, pObject );
end

local CGameScene_CreateObject = CGameScene.CreateObject;
function CGameScene:CreateObject( nClassID, nObjectID, vPos, pContext, nSize )
	local pObject = CGameScene_CreateObject( self, nClassID, nObjectID, vPos, pContext, nSize );

	local Event = {};
    Event.m_Type = "OnCreateObject";
	Event.m_Object = pObject;
	self.m_pWanfa.m_EventDispatcher:DispatchEvent( Event );

	return pObject;
end

local CGameScene_DestroyObject = CGameScene.DestroyObject;
function CGameScene:DestroyObject( pObject )
	local Event = {};
    Event.m_Type = "OnDestroyObject";
	Event.m_Object = pObject;
	self.m_pWanfa.m_EventDispatcher:DispatchEvent( Event );

	CGameScene_DestroyObject( self, pObject );
end

local CGameScene_Start = CGameScene.Start;
function CGameScene:Start()
	CGameScene_Start( self );

	local Event = {};
    Event.m_Type = "OnSceneStart";
	self.m_pWanfa.m_EventDispatcher:DispatchEvent( Event );
end

function CGameScene:GetWanfa()
	return self.m_pWanfa;
end

function CGameScene:CreatePlayerContex( nAccountID, nManorID, nHeadID, nEquipID, nMusicID, nSkillID, tblFaceID, nStarNum,
		nSkillMaxLevel, tblPassiveSkillID, tblPassiveSkillTopLevel, szNickName, nMatchTime, nEquipPassiveSkillTopLevel )
	-- SPlayerContex
	local pContext = CBufferStream:new( 200 );
	pContext:WriteUint64( nAccountID );
	pContext:WriteInt32( nManorID );
	pContext:WriteInt16( nHeadID );
	pContext:WriteInt16( nEquipID );
	pContext:WriteInt16( nMusicID );
	pContext:WriteInt16( nSkillID );
	for i = 1, MAX_BattleFace_Count do
		pContext:WriteInt8( tblFaceID[i] )			
	end
	pContext:WriteInt32( nStarNum );
	pContext:WriteInt8( nSkillMaxLevel );
	for i = 1, Max_Passive_Skill_Num do
		pContext:WriteInt16( tblPassiveSkillID[i] )			
	end
	for i = 1, Max_Passive_Skill_Num do
		pContext:WriteInt8( tblPassiveSkillTopLevel[i] )			
	end
	pContext:WriteInt32( nMatchTime );
	pContext:WriteInt8( nEquipPassiveSkillTopLevel );
	pContext:WriteUTFBytes( szNickName, CHARNAME_BYTE_SIZE + 1 );
	return pContext;
end

function g_GetSceneNodeTotal( nRoomType )
	local SceneInfo = CSceneList:Inst():GetInfo( nRoomType );
	local nSceneWidth = SceneInfo:GetWidth();
	local nSceneDeepth = SceneInfo:GetDepth();
	return nSceneWidth/16 * nSceneDeepth/16;
end

--endregion
