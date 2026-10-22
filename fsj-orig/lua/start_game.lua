-- Start the game: original client scripts (OnStart runs at load), then the in-process servers and scene hooks. Claude.
require "GameClientRequire"
require "server/fake_world"
require "server/world_handlers"
if SceneInstallHooks then SceneInstallHooks() end
if LoginInstallHooks then LoginInstallHooks() end
if SceneMatch then SceneMatch.InstallHooks() end
if SceneSkills then SceneSkills.InstallHooks() end
if SceneBattleHUD then SceneBattleHUD.InstallHooks() end

require "natives.scene_lan"
SceneLAN.InstallHooks()
