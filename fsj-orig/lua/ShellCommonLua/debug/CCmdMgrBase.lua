--region CCmdMgrBase.lua
--GM 命令
--此文件由[BabeLua]插件自动生成

function CCmdMgrBase:Ctor()
 	local szDesignerPath = g_App:GetGameSettingPath();
	self.m_tblCmdMap = {}
	self:RegisterAll();
end

function CCmdMgrBase:Register( sCmdName, funCmd, sHelpText )
	if ( nil == sCmdName or nil == funCmd ) then
		return;
	end
	sCmdName = string.lower( sCmdName ) 
	self.m_tblCmdMap[sCmdName] = funCmd;
end

function CCmdMgrBase:ParseCmd( sCmdStr )
	local tblParam = {}
	local sCmdName = nil;
	for sMatch in ( sCmdStr.." " ) : gmatch( "(.-)".." " ) do
		if nil == sCmdName then
			if funName ~= "setdb" then
				sCmdName = string.lower( sMatch );
			else
				sCmdName = sMatch;
			end
		elseif sMatch ~= "" then
			table.insert( tblParam, sMatch )
		end
    end

	local funCmd = self.m_tblCmdMap[ sCmdName ];	
	if( funCmd == nil ) then
		print( "Invalid GM", sCmdStr );
	else
		if type( funCmd ) == "string" then
			self[funCmd]( self, unpack( tblParam ) );
		else
			funCmd( unpack( tblParam ) );
		end
	end
end

function CCmdMgrBase:RegisterAll()
	self:Register( "reload", 
		function( file ) 
			dofile( file ); 
		end );
    self:Register( "dumpmemory", 
		function()
            DumpMemoryInfo();
		end );
    self:Register( "dumptick", 
		function()
            CTick.DumpTick();
		end );
	self:Register( "gdb", 
		function() 
			gdb(); 
		end );
	self:Register( "gcall",
		function()
			g_App:GCAll();
		end );
	self:Register( "ohmygod",
		function()
			g_App:UnRegister( nil );
		end );
    self:Register( "stopai", 
		function( bStop )
			self.m_Player:GetScene():StopAI( bStop == nil or tonumber( bStop ) ~= 0 );
		end );
	self:Register( "setremaintime",
		function( nNum )
			self.m_Player:GetScene():SetTimeRemain( nNum );
		end );
	self:Register( "getpos",
		function()
			local PixelPos = self.m_Player:GetPixelPos();
			print( "CurPos is", PixelPos:x(), PixelPos:y(), math.floor( PixelPos:x() / 16 ), math.floor( PixelPos:y() / 16 ));
		end );
	self:Register( "finditem",
		function( nPosX, nPosY, nType )
			local Pos = CPos16:new();
			Pos:x( nPosX );
			Pos:y( nPosY );
			print( "FindItem Type :", nType, self.m_Player:GetScene():FindItemType( Pos, nType ) );
		end );
	self:Register( "suicide",
		function()
			self.m_Player:Suicide();
		end );
end

--endregion
