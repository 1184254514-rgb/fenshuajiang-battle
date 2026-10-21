--region CBufferStream.lua
--Date 2015-12-18

function CBufferStream:Ctor( nSize )
	if nSize then
		self:SetDataSize( nSize );
	end
end

function CBufferStream:ReadUCS32()
    local nCount = self:ReadUint32();
	return self:ReadUCSCounts( nCount );
end

function CBufferStream:ReadUTF32()
    local nCount = self:ReadUint32();
	return self:ReadUTFBytes( nCount );
end

-- C++结构体
function UnpackStruScore( pBuffer )
	local tblData = {};
	tblData.nAllScore		= pBuffer:ReadUint32();
	tblData.nAllCoin		= pBuffer:ReadUint32();
	tblData.nAreaScore		= pBuffer:ReadUint32();
	tblData.nComboScore		= pBuffer:ReadUint32();
	tblData.nKillScore		= pBuffer:ReadUint32();
	tblData.nKillCount		= pBuffer:ReadUint8();
	tblData.nNodeCount		= pBuffer:ReadUint32();
	tblData.nPickUpCoin		= pBuffer:ReadUint32();
	tblData.aryMaxGrade		= {};
	for n = 1, eHG_Count do
		tblData.aryMaxGrade[n] = pBuffer:ReadUint32();
	end
	tblData.nSerialKillType = pBuffer:ReadUint8();
	tblData.nSerialKillCoin = pBuffer:ReadUint32();
	tblData.nMaxKillCoin	= pBuffer:ReadUint32();
	return tblData;
end

function PackStruScore( pBuffer, tblData )
	pBuffer:WriteInt32( tblData.nAllScore );
	pBuffer:WriteInt32( tblData.nAllCoin );
	pBuffer:WriteInt32( tblData.nAreaScore );
	pBuffer:WriteInt32( tblData.nComboScore );
	pBuffer:WriteInt32( tblData.nKillScore );
	pBuffer:WriteInt8( tblData.nKillCount );
	pBuffer:WriteInt32( tblData.nNodeCount );
	pBuffer:WriteInt32( tblData.nPickUpCoin );
	for n = 1, eHG_Count do
		pBuffer:WriteInt32( tblData.aryMaxGrade[n] );
	end
	pBuffer:WriteInt8( tblData.nSerialKillType );
	pBuffer:WriteInt32( tblData.nSerialKillCoin );
	pBuffer:WriteInt32( tblData.nMaxKillCoin );
end

function UnpackRhythmData( pBuffer )
	local tblData = {};
	tblData.m_nMaxCombo = pBuffer:ReadUint32();
	tblData.m_nTotle = pBuffer:ReadUint32();
	tblData.m_nEvaluate = pBuffer:ReadUint8();
	tblData.m_aryCount = {}
	for n = 1, eVal_Count do
		tblData.m_aryCount[n] = pBuffer:ReadUint32();
	end
	return tblData;
end

function PackRhythmData( pBuffer, tblData )
	pBuffer:WriteInt32( tblData.m_nMaxCombo );
	pBuffer:WriteInt32( tblData.m_nTotle );
	pBuffer:WriteInt8( tblData.m_nEvaluate );
	for n = 1, eVal_Count do
		pBuffer:WriteInt32( tblData.m_aryCount[n] );
	end
end

--endregion
