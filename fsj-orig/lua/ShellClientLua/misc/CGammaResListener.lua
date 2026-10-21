--region CGammaResListener.lua
--Date 2015-12-07

g_mapGammaResListener = {}

function CGammaResListener:Ctor( funCallBack, Context )
	self.m_funCallBack = funCallBack;
	self.m_Context = Context;
	g_mapGammaResListener[self] = self;
end

function CGammaResListener:OnLoadedEnd( pResFile, bFailed )
	g_mapGammaResListener[self] = nil;

	if self.m_funCallBack == nil then
		return;
	end

	if pResFile == nil then 
		bFailed = false;
	end

	if self.m_Context then
		self.m_funCallBack( self.m_Context, pResFile, not bFaile );
	else
		self.m_funCallBack( pResFile, not bFaile );
	end
end
