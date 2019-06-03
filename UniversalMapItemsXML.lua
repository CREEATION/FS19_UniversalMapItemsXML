--[[

    @name Universal Map Items XML
    @description Makes Placeables single- and multiplayer compatible, automatically.
    @release fs19-1.0

    @author CREE7EN
    @copyright 2019 Thomas Creeten, CREEATION.de
    @see https://github.com/CREEATION/FS19_UniversalMapItemsXML
    @usage create a single `mapItems.xml` for multiplayer. call this file via your modDesc.xml, adjust `singleplayerStartingFarmIds` here and you're done.

    Originally created for the map `Puur Nederland` by Mike-Modding.com
    @see https://mike-modding.com/files/file/58-fs19-puur-nederland-by-mike-moddingcom/

--]]

--- CONFIG
-- defines which farms one will own on first start in singleplayer
--
-- default: none (singleplayer doesn't own anything on first start)
-- possible values: `1-8`
-- examples:
--    { 1, 2, 3, 4, 5, 6, 7, 8 } -- you own all placeables on the map
--    { 2, 7, 8 } -- you own all placeables which have their farmIds set to `2`, `7` or `8`
--    {} -- you don't own any placeables
local config_singleplayerOwnsPlaceablesWithFarmIds = {}

--[[############################################################################

    CAUTION: there shouldn't be a reason to edit anything below.

    if you found a bug, report it on GitHub so I can add you as a collaborator!
    @see https://github.com/CREEATION/FS19_UniversalMapItemsXML/issues

############################################################################--]]

--- hook into the function which places items after all necessary checks and adjust the `ownerFarmId` as needed
-- @see https://gdn.giants-software.com/documentation_scripting_fs19.php?version=script&category=66&class=10359#finalizePlacement164130
Placeable.finalizePlacement = Utils.overwrittenFunction(
  Placeable.finalizePlacement,
  function ( self, superFunc )
    --- only do stuff if we're in singleplayer, as given `*items.xml` should already be multiplayer-compatible
    if not g_currentMission.missionDynamicInfo.isMultiplayer then
      --- check if any given farmId is out of range
      local farmIdsOutOfRange = {}
      local farmIdsOutOfRangeCount = 0
      local farmIdsTotalCount = 0

      for _, farmId in pairs( config_singleplayerOwnsPlaceablesWithFarmIds ) do
        --- count how many farmIds are present in total
        farmIdsTotalCount = farmIdsTotalCount + 1

        if farmId < 0 or farmId > 15 then
          table.insert( farmIdsOutOfRange, farmId )
          --- count how many farmIds are out of range
          farmIdsOutOfRangeCount = farmIdsOutOfRangeCount + 1
        end
      end

      --- throw a warning if there are farmIds out of range, indicating which ones
      if farmIdsOutOfRangeCount > 0 then
        --- save out-of-range farmIds in a single string for warning output
        local strFarmIdsOutOfRange = ''

        for _, farmIdOutOfRange in pairs( farmIdsOutOfRange ) do
          strFarmIdsOutOfRange = strFarmIdsOutOfRange .. '[' .. farmIdOutOfRange .. ']'
        end

        g_logManager:warning( "FarmIDs '%s' out of range! Possible values: [0-15] | UniversalPlaceables.lua", strFarmIdsOutOfRange )

        --- stop further custom script execution, proceed with original function
        return superFunc( self )
      end

      --- hold associated farmId of current placeable
      local ownerFarmId = self:getOwnerFarmId()

      --- check if farmId of current placeable belongs to someone, but not everyone (e.g. `1-14`)
      -- `AccessHandler.EVERYONE` = farmId `0`
      -- `AccessHandler.NOBODY` = farmId `15`
      if ownerFarmId ~= AccessHandler.EVERYONE and ownerFarmId ~= AccessHandler.NOBODY then
        --- iterate over given farmIds and set ownership as defined per config (in `config_singleplayerOwnsPlaceablesWithFarmIds`)
        for _, farmId in pairs( config_singleplayerOwnsPlaceablesWithFarmIds ) do
          --- we found a match!
          if ownerFarmId == farmId then
            --- this placeable belongs to the singleplayer farmer now
            self:setOwnerFarmId( FarmManager.SINGLEPLAYER_FARM_ID, true )
            --- exit the loop for this placeable, as one placeable only has one farmId associated anyways
            break
          end
        end

        --- get the possibly new ownerFarmId
        ownerFarmId = self:getOwnerFarmId()

        --- check if the ownerFarmId isn't the singleplayer farmer already
        -- edge case: also check if `config_singleplayerOwnsPlaceablesWithFarmIds` only contains `15` (e.g. `AccessHandler.NOBODY`),
        --            because in this case no placeable should already be defined for the singleplayer farmer (`1`, which happens to be equal
        --            to `FarmManager.SINGLEPLAYER_FARM_ID`) at all, so we proceed to set the ownerFarmId to `AccessHandler.NOBODY` here anyways
        if ( farmIdsTotalCount == 1 and config_singleplayerOwnsPlaceablesWithFarmIds[1] == 15 ) or ownerFarmId ~= FarmManager.SINGLEPLAYER_FARM_ID then
          --- and if it's not, set the ownership of this placeable to `AccessHandler.NOBODY` (e.g. `15`)
          -- the placeable can now be bought as usual in singleplayer, because it wasn't defined in the config table
          -- `config_singleplayerOwnsPlaceablesWithFarmIds` in the first place
          self:setOwnerFarmId( AccessHandler.NOBODY, true )
        end
      end

      -- FarmManager.SPECTATOR_FARM_ID :: 0
      -- FarmManager.SINGLEPLAYER_FARM_ID :: 1
      -- FarmManager.MAX_FARM_ID :: 8
      -- FarmManager.INVALID_FARM_ID :: 15
      -- FarmManager.MAX_NUM_FARMS :: 8

      -- DebugUtil.printTableRecursively( FarmlandManager )

      --- we're done here
      return superFunc( self )
    end
  end
)

--- prevents spectator farm from getting money in singleplayer every hour
-- this is related to a warning that appears if one would add `farmId="0"` (e.g. `FarmManager.SPECTATOR_FARM_ID`) in their placeables XML file
-- (`farmId="0"` was possibly meant to be set to `15` instead)
Placeable.hourChanged = Utils.overwrittenFunction(
  Placeable.hourChanged,
  function ( self, superFunc )
    if not g_currentMission.missionDynamicInfo.isMultiplayer then
      --- skip function execution if placeable belongs to spectator farm
      if self:getOwnerFarmId() ~= FarmManager.SPECTATOR_FARM_ID then
        superFunc( self )
      end
    end
  end
)
