--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

CValidateClient.EXTRA_SIZE = 
		ACCOUNT_BYTE_SIZE +
		LOGIN_TOKEN_SIZE +
		CHANNEL_BYTE_SIZE +
		SDKTYPE_BYTE_SIZE +
		LOGIN_PID_SIZE +
		LOGIN_GID_SIZE + 
		UUID_LEN +
		UUID_LEN +
		4 +
		GRAPHICDESC_LEN + 
		DEVICEDESC_LEN + 
		CPUTYPE_LEN + 
		OSDESC_LEN + 
		UUID_LEN +
		LANGUAGE_LEN + 
		8 + 4 + 4 + 4 + 2 + 2;

function CValidateClient:Ctor()
end

function CValidateClient:OnPack( Buffer )
	local CurVersion = g_App:GetDataVersion();
	Buffer:WriteInt32( CurVersion:GetLow32() );
	Buffer:WriteInt32( CurVersion:GetHigh32() );
	Buffer:WriteInt32( CValidateClient.EXTRA_SIZE );

	local nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szAccountName );
	Buffer:SetPosition( nStartPos + ACCOUNT_BYTE_SIZE );

	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szToken );
	Buffer:SetPosition( nStartPos + LOGIN_TOKEN_SIZE );

	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szChannel );
	Buffer:SetPosition( nStartPos + CHANNEL_BYTE_SIZE );

	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szSDKType );
	Buffer:SetPosition( nStartPos + SDKTYPE_BYTE_SIZE );
	
	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_pid );
	Buffer:SetPosition( nStartPos + LOGIN_PID_SIZE );
	
	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_gid );
	Buffer:SetPosition( nStartPos + LOGIN_GID_SIZE );

	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szGHomeDeviceID );
	Buffer:SetPosition( nStartPos + UUID_LEN );

	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szPushDeviceID );
	Buffer:SetPosition( nStartPos + UUID_LEN );

	Buffer:WriteInt32( self.m_nTime );

	-- 设备信息	
	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_MachineInfo.graphicDesc );
	Buffer:SetPosition( nStartPos + GRAPHICDESC_LEN );
	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_MachineInfo.deviceDesc );
	Buffer:SetPosition( nStartPos + DEVICEDESC_LEN );
	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_MachineInfo.cpuType );
	Buffer:SetPosition( nStartPos + CPUTYPE_LEN );
	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_MachineInfo.osDesc );
	Buffer:SetPosition( nStartPos + OSDESC_LEN );
	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_MachineInfo.uuid );
	Buffer:SetPosition( nStartPos + UUID_LEN );
	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_MachineInfo.languageCode );
	Buffer:SetPosition( nStartPos + LANGUAGE_LEN );
	Buffer:WriteInt32( self.m_MachineInfo.macLow );
	Buffer:WriteInt32( self.m_MachineInfo.macHight );
	Buffer:WriteInt32( self.m_MachineInfo.cpuFrequery );
	Buffer:WriteInt32( self.m_MachineInfo.cpuCount );
	Buffer:WriteInt32( self.m_MachineInfo.memSize );
	Buffer:WriteInt16( self.m_MachineInfo.screenX );
	Buffer:WriteInt16( self.m_MachineInfo.screenY );
end

function CValidateClient:OnUnpack( Buffer )

end

function CQueryExitGame:Ctor()
end

function CQueryExitGame:OnPack( Buffer )
	Buffer:WriteInt8( false );
end

function CQueryActivateCode:OnPack( Buffer )
	local nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.szKey );
	Buffer:SetPosition( nStartPos + ACTIVATE_CODE_BYTE_SIZE + 1 );
end		  
		  
function CQueryActivateCode:OnUnpack( Buffer )
end

function CCreateTeam:OnPack( Buffer )
    Buffer:WriteInt8( self.nType );
	Buffer:WriteInt8( self.nMaxMember );
end

function CJoinTeam:OnPack( Buffer )
	Buffer:WriteUint64( self.nTeamID );
	Buffer:WriteInt8( self.nTeamType );
end

function CSetMusic:OnPack( Buffer )
    Buffer:WriteInt16( self.nMusicID );
end

function CStartMatchTeam:OnPack( Buffer )
end

function CStopMatchTeam:OnPack( Buffer )
end

function CLeaveTeam:OnPack( Buffer )
    Buffer:WriteBoolean( self.bCreateNewTeam );
end

function CSearchPlayers:OnPack( Buffer )
	Buffer:WriteUTFBytes( self.szName, CHARNAME_BYTE_SIZE + 1 );
end		  
		  
function CSearchPlayers:OnUnpack( Buffer )
end

------------------CNotifyModifyCharName Begin---------------------
function CRename:Ctor()
	self.m_szCharName = nil;
end

function CRename:OnPack( Buffer )
	local nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szCharName );
	Buffer:SetPosition( nStartPos + CHARNAME_BYTE_SIZE + 1 );
end
------------------CNotifyModifyCharName End---------------------

function CLimitTimeRoom:Ctor()
end

function CLimitTimeRoom:OnPack( Buffer )
end

function CChangeHeadIcon:Ctor()
end

function CChangeHeadIcon:OnPack( Buffer )
    Buffer:WriteInt16( self.m_nIndex );
end

---------------CBuyMusic Begin ------------------
function CBuyMusic:Ctor()

end

function CBuyMusic:OnPack( Buffer )
	Buffer:WriteInt16( self.m_nMusicID );
end
--------------CBuyMusic End ---------------------
function CInvitePlayer:Ctor()
end

function CInvitePlayer:OnPack( Buffer )
    Buffer:WriteUint64( self.nAccountID );
end

function CJoinGame:Ctor()
end

function CJoinGame:OnPack( Buffer )
    Buffer:WriteUint64( self.nAccountID );
	Buffer:WriteUint64( self.nTeamID );
end

function CUsingSkin:Ctor()

end

function CUsingSkin:OnPack( Buffer )
    Buffer:WriteInt16( self.nSkinID );
end

function CBuySkin:Ctor()

end

function CBuySkin:OnPack( Buffer )
    Buffer:WriteInt16( self.nSkinID );
end

function CRefuseInvite:Ctor()

end

function CRefuseInvite:OnPack( Buffer )
    Buffer:WriteUint64( self.nAccountID );
end

function CCancelFRRename:Ctor()
end

function CCancelFRRename:OnPack( Buffer )
	Buffer:WriteUint64( self.nAccountID )
end

function CSpecialOffer:Ctor()
end

function CSpecialOffer:OnPack( Buffer )
end

function CEndlessData:Ctor()

end

function CEndlessData:OnPack( Buffer )
	Buffer:WriteInt32( self.m_nRunTime );
	Buffer:WriteInt32( self.m_nCurTaskScore );
	PackStruScore( Buffer, self.m_sScore );
	PackRhythmData( Buffer, self.m_sRhythmData );
	Buffer:WriteInt16( self.m_nStrikeOthersTipCount );
	Buffer:WriteInt16( self.m_nMakeManorTipCount );
	Buffer:WriteInt16( self.m_nStrikeSelfTipCount );
	Buffer:WriteInt16( self.m_nDiedTipCount );
end

----------------------------------------------
--------------------点赞-----------------------
----------------------------------------------
function CAddCommend:Ctor()

end

function CAddCommend:OnPack( Buffer )
	Buffer:WriteUint64( self.m_nBeCommendID );
end

----------------------------------------------
----------------无尽模式成绩记录----------------
---------------------------------------------
function CQueryPlayerBaseData:Ctor()

end

function CQueryPlayerBaseData:OnPack( Buffer )
	Buffer:WriteUint64( self.m_nAccountID );
end

function CGetAllRecordNew:Ctor()
end

function CGetAllRecordNew:OnPack( Buffer )
	Buffer:WriteUint64( self.m_nAccountID );
end

--gm 命令
function CSendWorldGMCmd:Ctor()
    self.m_scritp = ""; 
end

function CSendWorldGMCmd:OnPack( Buffer )
    Buffer:WriteUTF( self.m_scritp );
end

function CBuyRhythmNoticeBar:Ctor()
end

function CBuyRhythmNoticeBar:OnPack( Buffer )
	Buffer:WriteInt8( self.m_nIndex );
end

function CUseRhythmNoticeBar:Ctor()
end

function CUseRhythmNoticeBar:OnPack( Buffer )
	Buffer:WriteInt8( self.m_nIndex );	
end

function CBuyBattleFace:Ctor()
end

function CBuyBattleFace:OnPack( Buffer )
	Buffer:WriteInt8( self.m_nIndex );
end

function CUseBattleFace:Ctor()
end

function CUseBattleFace:OnPack( Buffer )
	Buffer:WriteInt8( self.m_nIndex );
	Buffer:WriteInt8( self.m_nType );
	Buffer:WriteInt8( self.m_bUsed );
end



function CObserveGame:Ctor()
end

function CObserveGame:OnPack( Buffer )
    Buffer:WriteUint64( self.m_nAccountID );
	Buffer:WriteUint64( self.m_nRaceRoomID );
end

function CAddCommendDay:Ctor()
end

function CAddCommendDay:OnPack( Buffer )
	Buffer:WriteUint64( self.nAccountIDTo );
end

function CQueryRainbowGold:Ctor()
end

function CQueryRainbowGold:OnPack( Buffer )
end

function CAlterUseSkill:Ctor()

end

function CAlterUseSkill:OnPack( Buffer )
	Buffer:WriteInt32( self.nSkillID );
end
--解锁宝箱  
function CUnLockTreasureBox:Ctor()
end

function CUnLockTreasureBox:OnPack( Buffer )
	Buffer:WriteInt32( self.m_nTreasureBoxID );
	Buffer:WriteInt32( self.m_nGetTime );
	Buffer:WriteInt32( self.m_nPosIndex );
end

--加速宝箱  
function CAccelerateTreasureBox:Ctor()
end

function CAccelerateTreasureBox:OnPack( Buffer )
	Buffer:WriteInt32( self.m_nTreasureBoxID );
	Buffer:WriteInt32( self.m_nGetTime );
end

--可开启宝箱
function CCouldOpenTreasureBox:Ctor()
end

function CCouldOpenTreasureBox:OnPack( Buffer )
	Buffer:WriteInt32( self.m_nTreasureBoxID );
	Buffer:WriteInt32( self.m_nGetTime );
end

--开启宝箱
function COpenTreasureBox:Ctor()
end

function COpenTreasureBox:OnPack( Buffer )
	Buffer:WriteInt32( self.m_nTreasureBoxID );
	Buffer:WriteInt32( self.m_nGetTime );
	Buffer:WriteInt32( self.m_nPosIndex);
end

--扔掉宝箱  
function CDiacardTreasureBox:Ctor()
end

function CDiacardTreasureBox:OnPack( Buffer )
	Buffer:WriteInt32( self.m_nTreasureBoxID );
	Buffer:WriteInt32( self.m_nGetTime );
end

--合成物品  
function CFusion:Ctor()
end

function CFusion:OnPack( Buffer )
	Buffer:WriteInt32( self.m_nFusionID );
end

function CVideoGuideLog:Ctor()
end

function CVideoGuideLog:OnPack( Buffer )
	Buffer:WriteBoolean( self.bFull );
	Buffer:WriteInt32( self.nRecord );
end

function CCheckEnterRoom:Ctor()
end

function CCheckEnterRoom:OnPack( Buffer )
	Buffer:WriteInt8( self.m_nRoomType );
end

function CSettingLog:Ctor()
end

function CSettingLog:OnPack( Buffer )
	Buffer:WriteInt8( self.nSettingNum );
	Buffer:WriteUTFBytes( self.szSettingName );
	Buffer:WriteUTFBytes( "\0" );
end

function CShareResult:Ctor()
end

function CShareResult:OnPack( Buffer )
	local nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szSrcName );
	Buffer:SetPosition( nStartPos + 32 );
	
	nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szDesName );
	Buffer:SetPosition( nStartPos + 32 );

	Buffer:WriteBoolean( self.m_bSucc );
	Buffer:WriteBoolean( self.m_bShareLink );
end

function CQueryChangeMatchPos:Ctor()

end

function CQueryChangeMatchPos:OnPack( Buffer )
	Buffer:WriteUint64( self.nTeamID );
	Buffer:WriteInt8( self.nRequestPos );
	Buffer:WriteInt8( self.nResponsePos );
end

function CAnswerChangeMatchPos:Ctor()

end

function CAnswerChangeMatchPos:OnPack( Buffer )
	Buffer:WriteUint64( self.nTeamID );
	Buffer:WriteUint64( self.nRequestAccountID );
	Buffer:WriteInt8( self.nRequestPos );
	Buffer:WriteInt8( self.nResponsePos );
	Buffer:WriteBoolean( self.bAgree );
end

function CChangeMatchReady:Ctor()
end

function CChangeMatchReady:OnPack( Buffer )
	Buffer:WriteUint64( self.nTeamID );
	Buffer:WriteBoolean( self.bAgree );
end

function CMatchPosHandle:Ctor()
end

function CMatchPosHandle:OnPack( Buffer )
	Buffer:WriteUint64( self.nTeamID );
	Buffer:WriteInt8( self.nType );
	Buffer:WriteInt8( self.nPos );
end

function CDeclaration:OnPack( Buffer )
end
function CQueryActivity:Ctor()
end

function CQueryActivity:OnPack( Buffer )
	Buffer:WriteInt8( self.nHandleType );
	Buffer:WriteInt8( self.nActivityType );
end

function CAlterPassiveSkill:Ctor()
end

function CAlterPassiveSkill:OnPack( Buffer )
	Buffer:WriteInt16( self.nSkillID );
end

function CUpgradeSkill:Ctor()
end

function CUpgradeSkill:OnPack( Buffer )
	Buffer:WriteInt16( self.nSkillID );
end

function CDelockSkill:Ctor()
end

function CDelockSkill:OnPack( Buffer )
	Buffer:WriteInt16( self.nSkillID );
end

function CGuestUpgrade:Ctor()
end

function CGuestUpgrade:OnPack( Buffer )
end

function CAlterFirstEvent:Ctor()
end

function CAlterFirstEvent:OnPack( Buffer )
	Buffer:WriteInt16( self.nFirstEventType );
end

function CQueryPrize:Ctor()
end

function CQueryPrize:OnPack( Buffer )
	Buffer:WriteInt32( self.m_nPrizeID );
end

function CQueryVipPrize:Ctor()
end

function CQueryVipPrize:OnPack( Buffer )
end


function CQueryWorldRaceInfo:Ctor()
end

function CQueryWorldRaceInfo:OnPack( Buffer )
	Buffer:WriteInt8( self.nType );
end

function CJoinRace:Ctor()
end

function CJoinRace:OnPack( Buffer )
	--Buffer:WriteInt8( self.nRaceType );
	Buffer:WriteUint64( self.nRaceRoomID );
end

function CSendMsg2CustomerService:Ctor()
end

function CSendMsg2CustomerService:OnPack( Buffer )
	Buffer:WriteInt8( self.Info.nType );
	Buffer:WriteUint64( self.Info.nQQ );
	Buffer:WriteUint64( self.Info.nPhone );
	Buffer:WriteInt32( self.Info.nChargeTime );
	Buffer:WriteInt8( string.len( self.Info.szChargeName ) );
	Buffer:WriteInt16( string.len( self.szContent ) );
	Buffer:WriteUTFBytes( self.Info.szChargeName );
	Buffer:WriteUTFBytes( self.szContent );
end

function CReciveCustomerServiceAnswer:Ctor()
end

function CReciveCustomerServiceAnswer:OnPack( Buffer )
	Buffer:WriteInt32( self.nID );
end

function CAlterPlayerInfo:Ctor()
end

function CAlterPlayerInfo:OnPack( Buffer )
	Buffer:WriteInt8( self.m_nNewSex );
	Buffer:WriteInt8( self.m_nNewAge );
	Buffer:WriteInt8( self.m_nNewConstellation );
	Buffer:WriteInt8( self.m_nNewArea );
end

function CAlterSignature:Ctor()
end

function CAlterSignature:OnPack( Buffer )
	local nStartPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szNewSignature );
	Buffer:SetPosition( nStartPos + Char_Signature_Byte_Size + 1 );
end


function CAddReport:Ctor()

end

function CAddReport:OnPack( Buffer )
	Buffer:WriteUint64( self.m_nBRAccountID );
	Buffer:WriteInt8( self.m_nReportType );
	Buffer:WriteInt8( self.m_nRoomType );
	Buffer:WriteInt8( string.len( self.m_szReportContent ) );
	Buffer:WriteUTFBytes( self.m_szReportContent );
end

function CGetFirstChargePrize:Ctor()
end

function CGetFirstChargePrize:OnPack()
end

function CCreateClan:Ctor()
end

function CCreateClan:OnPack( Buffer )
	Buffer:WriteInt16( self.m_nClanIcon );
	local nPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szClanName );
	Buffer:SetPosition( nPos + CLANNAME_BYTE_SIZE + 1 );
	nPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szClanSlogan );
	Buffer:SetPosition( nPos + CLANSLOGAN_BYTE_SIZE + 1 );
	Buffer:WriteInt8( self.m_nNeedApprove );
end

function CUploadPicture:Ctor()
end

function CUploadPicture:OnPack( Buffer )
	Buffer:WriteInt8( self.m_nPictureType );
	Buffer:WriteInt32( self.m_nBufferSize );
	Buffer:WriteBytes( self.m_buffer, 0, self.m_nBufferSize );
end

function CDeletePicture:Ctor()
end

function CDeletePicture:OnPack( Buffer )
	Buffer:WriteInt8( self.m_nPictureType );
	Buffer:WriteInt8( self.m_nPictureIndex );
end

function CQueryPropellPlayer:Ctor()
end

function CQueryPropellPlayer:OnPack( Buffer )
	Buffer:WriteInt32( self.m_nQueryPage );
end

function CQueryPictureData:Ctor()
end

function CQueryPictureData:OnPack( Buffer )
end