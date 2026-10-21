--region ShellCommon.lua
--Date 2015-12-15

----------------------包含文件----------------------
require "misc/CBufferStream"
require "misc/CEventDispatcher"
require "misc/ConfigLoadHelp"
require "misc/CTableConfigMgr"
require "misc/CTick"
require "misc/GammaMath"
require "misc/Help"
require "misc/Hash"
require "misc/json"
require "misc/CommonConstDefine"

require "protocal/PrtShellClientWorldID"
require "protocal/PrtShellClientRankID"
require "protocal/PrtShellClientSocialID"
require "protocal/PrtShellClientFieldID"
require "protocal/PrtShellWorldFieldID"
require "protocal/PrtBase"
require "protocal/PrtShellRegister"
require "protocal/PrtShellClient2World"
require "protocal/PrtShellClient2Field"
require "protocal/PrtShellClient2Rank"
require "protocal/PrtShellClient2Social"
require "protocal/PrtShellWorld2Client"
require "protocal/PrtShellField2Client"
require "protocal/PrtShellRank2Client"
require "protocal/PrtShellSocial2Client"
require "protocal/PrtShellWorld2Field"
require "protocal/PrtShellField2World"

require "debug/CCmdMgrBase"

require "scene/CGameScene"
require "character/CPlayer"
require "character/CCharacter"

require "playerdata/CPlayerDB"

require "wanfa/CWanfaBase"
--endregion
