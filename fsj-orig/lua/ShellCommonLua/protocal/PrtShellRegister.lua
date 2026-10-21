--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--注册声明协议类
g_PrtClient2WorldClass = {}
g_PrtWorld2ClientClass = {}
RegisterProtocal( g_tblPrtClient2World, g_PrtClient2WorldClass );
RegisterProtocal( g_tblPrtWorld2Client, g_PrtWorld2ClientClass );

g_PrtClient2FieldClass = {}
g_PrtField2ClientClass = {}
RegisterProtocal( g_tblPrtClient2Field, g_PrtClient2FieldClass, true );
RegisterProtocal( g_tblPrtField2Client, g_PrtField2ClientClass, true );

g_PrtWorld2FieldClass = {}
g_PrtField2WorldClass = {}
RegisterProtocal( g_tblPrtWorld2Field, g_PrtWorld2FieldClass );
RegisterProtocal( g_tblPrtField2World, g_PrtField2WorldClass );

g_PrtClient2RankClass = {}
g_PrtRank2ClientClass = {}
RegisterProtocal( g_tblPrtClient2Rank, g_PrtClient2RankClass );
RegisterProtocal( g_tblPrtRank2Client, g_PrtRank2ClientClass );

g_PrtClient2SocialClass = {}
g_PrtSocial2ClientClass = {}
RegisterProtocal( g_tblPrtClient2Social, g_PrtClient2SocialClass );
RegisterProtocal( g_tblPrtSocial2Client, g_PrtSocial2ClientClass );

--endregion
