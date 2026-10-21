--region CTick.lua
--Date 2015-12-18

local s_nLuaTickStart = eSCT_CppTickCount + 1;
local s_tblTickName2Index = {}

local function GetTickIndex( funHandler )
	if type( funHandler ) ~= "string" then
		return nil;
	end
	local nIndex = s_tblTickName2Index[funHandler]
	if nIndex then
		return nIndex;
	end
	nIndex = s_nLuaTickStart;
	s_nLuaTickStart = s_nLuaTickStart + 1;
	s_tblTickName2Index[funHandler] = nIndex;
end

function CTick.GetTickID()
	local szTickID = "";
	for k, v in pairs( s_tblTickName2Index ) do
		szTickID = szTickID .. tostring( k ) .. "\t" .. tostring( v ) .. "\n";
	end
	return szTickID;
end

function CTick.DumpTick()
	for k, v in pairs( s_tblTickName2Index ) do
		print( k, v );
	end
end

--[[
 * @param funTick Tick函数
 * @param pHandler 一般用于保存注册Tick的窗口
 * @param nRepeatCount 重复次数，0表示无限次
 * @param Context Tick上下文( 你想存什么就存什么=。= )
 * @param funComplete 当nRepeatCount不为0时，Tick完成nRepeatCount次后，funComplete被调用
 * @param bLocal 是否本地Tick（不与与服务器同步)
--]]
function CTick:Ctor( funTick, pHandler, pLocalTickMgr, nRepeatCount, Context, funComplete )
	self.m_pLocalTickMgr = pLocalTickMgr;
	self.m_funTick = funTick;
	self.m_pHandler = pHandler;
	self.m_nTickCount = 0;
	self.m_TickContext = Context;
	self.m_nRepeatCount = nRepeatCount;
	self.m_funTickComplete = funComplete;
    self.m_nTickIndex = GetTickIndex( funTick );
end
	
function CTick:OnTick()
	self.m_nTickCount = self.m_nTickCount + 1;
	local funTick = self.m_funTick;
	local funTickComplete = self.m_funTickComplete;		
	local pHandler = self.m_pHandler;
	local Context = self.m_TickContext;

	if ( self.m_nRepeatCount and self.m_nTickCount >= self.m_nRepeatCount ) then
		self:Stop();	
		if 	funTickComplete then
			if pHandler == nil then
				funTickComplete( Context )
			elseif type( funTickComplete ) == "string" then
				pHandler[funTickComplete]( pHandler, Context )
			else
				funTickComplete( pHandler, Context )
			end	
		end
	end
	
	if pHandler == nil then
		funTick( Context )
	elseif type( funTick ) == "string" then
		pHandler[funTick]( pHandler, Context )
	else
		funTick( pHandler, Context )
	end	
end

function CTick:SetLocal( pLocalTickMgr )
	self.m_pLocalTickMgr = pLocalTickMgr;
end
				
function CTick:Start( nInterval, bResetCount, pLocalTickMgr )
	if( self:IsRegisted() ) then
		g_App:UnRegister( self );		
	end

	pLocalTickMgr = pLocalTickMgr or self.m_pLocalTickMgr;
	local nIndex = self.m_nTickIndex or eSCT_CppTickCount;
	if not pLocalTickMgr then
		g_App:Register( self, nInterval, nIndex );
	elseif type( pLocalTickMgr ) == "table" then
		pLocalTickMgr:Register( self, nInterval, nIndex );
	else
		g_App:RegisterLocal( self, nInterval, nIndex );
	end
    self.m_nTickCount = bResetCount and 0 or self.m_nTickCount;
end
		
function CTick:GetTickCount()
	return self.m_nTickCount;
end
		
function CTick:GetRepeatCount()
	return self.m_nRepeatCount;
end
		
function CTick:SetTickCount( nCount )
	self.m_nTickCount = nCount;
end
		
function CTick:SetRepeatCount( nCount )
	self.m_nRepeatCount = nCount;
end
		
function CTick:GetTickFun()
	return self.m_funTick;
end

function CTick:SetTickFun( funTick )
	self.m_funTick = funTick;
    self.m_nTickIndex = GetTickIndex( funTick );
end

function CTick:GetTickCompleteFun()
	return self.m_funTickComplete;
end

function CTick:SetTickCompleteFun( fun )
	self.m_funTickComplete = value;
end

function CTick:GetContext()
	return self.m_TickContext;
end

function CTick:SetContext( Context )
	self.m_TickContext = Context;
end

--endregion
