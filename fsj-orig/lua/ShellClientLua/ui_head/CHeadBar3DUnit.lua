--region CHeadBar3DUnit.lua
--Date	2017/11/13
--此文件由[BabeLua]插件自动生成

function CHeadBar3DUnit:Ctor( parent, unit )
    self.m_maximum = 100;
    self.m_value = 50;
    self.m_tailValue = 0;
    self.m_rate = 0.33;
    self.m_flash = 0;
    self.m_flashTime = 0.1;
    self.m_Parent = parent
    self.m_tick = CTick:new( "UpdateImages", self );

    self.m_unit = unit;
    self.m_progressImg = self.m_unit:GetImageGroup( eST_FILL );
    self.m_progressImg:AddRef();
    self.m_bound = CFRect:new();
    self.m_progressImg:GetBounds( self.m_bound );
    self.m_wndRect = self.m_progressImg:GetImageWndRect( 1 );
    self.m_texRect = self.m_progressImg:GetImageTextureRect( 1 );
    self.m_wndRect1 = self.m_progressImg:GetImageWndRect( 0 );
    self.m_texRect1 = self.m_progressImg:GetImageTextureRect( 0 );
    self.m_texMaxLeft = self.m_texRect:left();
    self.m_texMaxRight = self.m_texRect:right();
end

function CHeadBar3DUnit:Destroy()
    if self.m_progressImg ~= nil then
        self.m_progressImg:Release();
        self.m_progressImg = nil;
    end
    self.m_unit = nil;
    self.m_tick:Stop();
end

function CHeadBar3DUnit:SetVisible( bValue )
	if self.m_unit then
		self.m_unit:SetVisible( bValue );
	end
end

function CHeadBar3DUnit:SetBarColor( tblColor )
	self.m_tblColor = { tblColor[1], tblColor[2] };
	self:UpdateImageRect();
end

function CHeadBar3DUnit:SetValue( value )
    if self.m_tailValue < value then
        self.m_tailValue = value;
    elseif self.m_tailValue > value then
        if self.m_flash > 0 and self.m_flash <= 1 then
            self.m_flash = 2;
        else
            self.m_flash = 1;
        end
    end
    if value == self.m_value then
        return;
    end
    self.m_value = value;
    self:UpdateImageRect();
end

function CHeadBar3DUnit:SetMax( value )
	self.m_maximum = value;
end

function CHeadBar3DUnit:UpdateImageRect()
    if self.m_progressImg == nil then
        return;
    end

    self.m_imageRect = CFRect:new();
    self.m_imageRect:left(self.m_bound:left());
    self.m_imageRect:top(self.m_bound:top());
    self.m_imageRect:right(self.m_bound:right()); 
    self.m_imageRect:bottom(self.m_bound:bottom());
    self.m_imageRect:right( self.m_imageRect:left() + 
        self.m_value / self.m_maximum * self.m_imageRect:Width());

    local rect = CFRect:new();
    rect:left( math.max( self.m_imageRect:left(), self.m_wndRect:left() ));
    rect:top( math.max( self.m_imageRect:top(), self.m_wndRect:top() ));
    rect:right( self.m_imageRect:right() );
    rect:bottom( math.min( self.m_imageRect:bottom(), self.m_wndRect:bottom() ));
    self.m_progressImg:SetImageWndRect( 1, rect );
    local rect1 = CFRect:new();
    if self.m_wndRect:Width() == 0 then
        rect1:left( self.m_texMaxLeft );
	    rect1:top( ( rect:top() - self.m_wndRect:top() ) / self.m_wndRect:Height() * self.m_texRect:Height() + self.m_texRect:top());
	    rect1:right( self.m_texMaxRight );
	    rect1:bottom( rect1:top() +  rect:Height() / self.m_wndRect:Height() * self.m_texRect:Height());
    else
        rect1:left( ( rect:left() - self.m_wndRect:left() ) / self.m_wndRect:Width() * self.m_texRect:Width() + self.m_texRect:left());
	    rect1:top( ( rect:top() - self.m_wndRect:top() ) / self.m_wndRect:Height() * self.m_texRect:Height() + self.m_texRect:top());
	    rect1:right( rect1:left() +  rect:Width() / self.m_wndRect:Width() * self.m_texRect:Width());
	    rect1:bottom( rect1:top() +  rect:Height() / self.m_wndRect:Height() * self.m_texRect:Height());
    end
    self.m_progressImg:SetImageTextureRect( 1, rect1 );
    self.m_tick:Start( 30 );
    self:UpdateImages();
end

function CHeadBar3DUnit:UpdateImages()
    if self.m_progressImg == nil then
        return;
    end
    local deltaTime =  33;
    if self.m_flash > 0 then
    	self.m_flash = self.m_flash - deltaTime / self.m_flashTime / 1000;
		if self.m_flash < 0 then
            self.m_flash = 0;
        end
    end
    local curRate = self.m_rate * ( 1 + ( self.m_tailValue - self.m_value ) / self.m_maximum * 2 );
	self.m_tailValue = self.m_tailValue - deltaTime * curRate * self.m_maximum / 1000;
	if( self.m_tailValue < self.m_value ) then
		self.m_tailValue = self.m_value;
	end	
	if( self.m_tailValue == self.m_value and self.m_flash == 0 ) then
		self.m_tick:Stop();
	end
	local percent = self.m_value / self.m_maximum;
	local tailPercent = self.m_tailValue / self.m_maximum;
	if( tailPercent > 1 )then
		tailPercent = 1;
		self.m_tailValue = self.m_maximum;
    end
    self.m_imageRect1 = CFRect:new();
    self.m_imageRect1:left(self.m_bound:left());
    self.m_imageRect1:top(self.m_bound:top());
    self.m_imageRect1:right(self.m_bound:right()); 
    self.m_imageRect1:bottom(self.m_bound:bottom());

    self.m_imageRect1:right( self.m_imageRect1:left() + tailPercent * self.m_imageRect1:Width());

    local rect = CFRect:new();
    rect:left( math.max( self.m_imageRect1:left(), self.m_wndRect1:left() ));
    rect:top( math.max( self.m_imageRect1:top(), self.m_wndRect1:top() ));
    rect:right( math.min( self.m_imageRect1:right(), self.m_wndRect1:right() ));
    rect:bottom( math.min( self.m_imageRect1:bottom(), self.m_wndRect1:bottom() ));
    self.m_progressImg:SetImageWndRect( 0, rect );
    local rect1 = CFRect:new();
    rect1:left( ( rect:left() - self.m_wndRect1:left() ) / self.m_wndRect1:Width() * self.m_texRect1:Width() + self.m_texRect1:left());
	rect1:top( ( rect:top() - self.m_wndRect1:top() ) / self.m_wndRect1:Height() * self.m_texRect1:Height() + self.m_texRect1:top());
	rect1:right( rect1:left() +  rect:Width() / self.m_wndRect1:Width() * self.m_texRect1:Width());
	rect1:bottom( rect1:top() +  rect:Height() / self.m_wndRect1:Height() * self.m_texRect1:Height());
    self.m_progressImg:SetImageTextureRect( 0, rect1 );

    local flashColor;
    if self.m_flash > 0 and self.m_flash <= 1 then
        flashColor = "bb";
    else
        flashColor = "00";
    end

    local cColor = "0xff"..flashColor..flashColor..flashColor;
	self.m_progressImg:SetImageColor( 0, cColor );

	if self.m_tblColor then
		self.m_progressImg:SetImageHue( 1, -self.m_tblColor[1]/180 );
		self.m_progressImg:SetImageColor( 1, self.m_tblColor[2] );
	end
end
--endregion
