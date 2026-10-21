--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

CSortInfo.GRADE_NUM = 256;

function CSortInfo:Ctor( nSize )
    self.m_vecGradeTips = nil;
	self:Init();

    self.m_nMaxNum = nSize;
    self.m_nCurNum = 0;
end

function CSortInfo:Init()
	self.m_vecGradeTips = {};
	for i = 0, CSortInfo.GRADE_NUM - 1 do
		self.m_vecGradeTips[i+1] = {};
	end
	self.m_nCurNum = 0;
end

--往头插
function CSortInfo:Unshift( strText, nGrade )
    if nGrade >= CSortInfo.GRADE_NUM then
        nGrade = CSortInfo.GRADE_NUM-1;
    end
			
    if self.m_nCurNum >= self.m_nMaxNum then
        for i = 0, CSortInfo.GRADE_NUM-1 do
            local vecGradeString = self.m_vecGradeTips[i+1];
            if vecGradeString and #vecGradeString > 0 then
                table.remove( vecGradeString, #vecGradeString );
                self.m_nCurNum = self.m_nCurNum - 1;
                break;
            end
        end
    end

    local vecGradeString = self.m_vecGradeTips[nGrade+1];
    table.insert( vecGradeString, 1, strText );
    self.m_nCurNum = self.m_nCurNum + 1;
end
		
function CSortInfo:GetLength()
    return self.m_nCurNum;
end

--获取并删除结尾 
function CSortInfo:Pop()
    for i = CSortInfo.GRADE_NUM-1, 0, -1 do
        local vecGradeString = self.m_vecGradeTips[i+1];
        if vecGradeString and #vecGradeString > 0 then
            self.m_nCurNum = self.m_nCurNum - 1;
            local strGradeTip = vecGradeString[#vecGradeString];
            table.remove( vecGradeString, #vecGradeString );
            return strGradeTip;
        end
    end
    return nil;
end

--endregion
