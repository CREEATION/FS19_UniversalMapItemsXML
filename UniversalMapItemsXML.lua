--[[

    @name Universal Map Items XML
    @description Makes Placeables single- and multiplayer compatible, automatically.
    @release fs19-0.7a

    @author CREE7EN
    @copyright 2019 Thomas Creeten, CREEATION.de
    @see https://github.com/CREEATION/FS19_UniversalMapItemsXML
    @usage create a single `mapItems.xml` for multiplayer. call this file via your modDesc.xml, adjust `singleplayerStartingFarmIds` here and you're done.

    Originally created for the map `Puur Nederland` by Mike-Modding.com
    @see https://mike-modding.com/files/file/58-fs19-puur-nederland-by-mike-moddingcom/

--]]

--[[############################################################################

    CAUTION: there shouldn't be a reason to edit anything below.

    if you found a bug, report it on GitHub so I can add you as a collaborator!
    @see https://github.com/CREEATION/FS19_UniversalMapItemsXML/issues

############################################################################--]]

UniversalMapItemsXML = {}
-- UniversalMapItemsXML.singleplayerOwnedFarmIds = {}
UniversalMapItemsXML.enableDebugMode = false

--- @TODO
-- function UniversalMapItemsXML:configContainsFarmId( farmId )
--   for _, configFarmId in ipairs( self.singleplayerOwnedFarmIds ) do
--     if configFarmId == farmId then
--       return true
--     end
--   end
--
--   return false
-- end

--- @TODO
-- function UniversalMapItemsXML:deleteMap() end
-- function UniversalMapItemsXML:loadMap()
--   if self.enableDebugMode then
--     g_logManager:info( "starting 'UniversalMapItemsXML.loadMap'... | UniversalMapItemsXML.lua" )
--   end
--
--   local mapModDesc = loadXMLFile( 'modDesc', g_currentMission.baseDirectory .. 'modDesc.xml' )
--   local configSingleplayerOwnedFarmIds = getXMLString( mapModDesc, 'modDesc.singleplayer#takeOverFarmIds' )
--
--   if configSingleplayerOwnedFarmIds ~= nil then
--     if self.enableDebugMode then
--       g_logManager:info( "found takeOverFarmIds: '%s' | UniversalMapItemsXML.lua", configSingleplayerOwnedFarmIds )
--     end
--
--     for _, farmId in ipairs( StringUtil.splitString( ' ', configSingleplayerOwnedFarmIds ) ) do
--       table.insert( self.singleplayerOwnedFarmIds, tonumber( farmId ) )
--
--       if self.enableDebugMode then
--         g_logManager:info( "populating 'UniversalMapItemsXML.singleplayerOwnedFarmIds' with '%s' | UniversalMapItemsXML.lua", farmId )
--       end
--     end
--
--     if self.enableDebugMode then
--       local strFarmIds = ''
--
--       for _, farmId in ipairs( self.singleplayerOwnedFarmIds ) do strFarmIds = strFarmIds .. '[' .. farmId .. ']' end
--
--       g_logManager:info( "populated 'UniversalMapItemsXML.singleplayerOwnedFarmIds' with '%s' | UniversalMapItemsXML.lua", strFarmIds )
--     end
--   end
-- end

--- hook into the function which places items after all necessary checks and adjust the `ownerFarmId` as needed
-- @see https://gdn.giants-software.com/documentation_scripting_fs19.php?version=script&category=66&class=10359#finalizePlacement164130
Placeable.finalizePlacement = Utils.overwrittenFunction(
  Placeable.finalizePlacement,
  function ( self, superFunc )
    if UniversalMapItemsXML.enableDebugMode then
      g_logManager:info( "placed '%s' into the world... | UniversalMapItemsXML.lua", self.i3dFilename )
    end

    --- only do stuff if we're in singleplayer on first map start, as given `*items.xml` should already be multiplayer-compatible
    if g_currentMission.missionInfo.isNewSPCareer then
      local farmIdsOutOfRange = {}
      local farmIdsOutOfRangeCount = 0
      local farmIdsTotalCount = 0

      --- check if any given farmId is out of range
      for _, farmId in ipairs( UniversalMapItemsXML.singleplayerOwnedFarmIds ) do
        --- count how many farmIds are present in total
        farmIdsTotalCount = farmIdsTotalCount + 1

        if farmId < FarmManager.SPECTATOR_FARM_ID or farmId > FarmManager.MAX_FARM_ID then
          table.insert( farmIdsOutOfRange, farmId )
          --- count how many farmIds are out of range
          farmIdsOutOfRangeCount = farmIdsOutOfRangeCount + 1
        end
      end

      --- throw a warning if there are farmIds out of range, indicating which ones
      if farmIdsOutOfRangeCount > 0 then
        --- save out-of-range farmIds in a single string for warning output
        local strFarmIdsOutOfRange = ''

        for _, farmIdOutOfRange in ipairs( farmIdsOutOfRange ) do
          strFarmIdsOutOfRange = strFarmIdsOutOfRange .. '[' .. farmIdOutOfRange .. ']'
        end

        g_logManager:warning( "FarmIDs '%s' out of range! Possible values: [0-8] | UniversalMapItemsXML.lua", strFarmIdsOutOfRange )

        --- stop further custom script execution, proceed with original function
        return superFunc( self )
      end

      --- hold associated farmId of current placeable
      local ownerFarmId = self:getOwnerFarmId()

      if UniversalMapItemsXML.enableDebugMode then
        g_logManager:info( "placeable ownerFarmId: '%s' | UniversalMapItemsXML.lua", tostring( ownerFarmId ) )
      end

      --- quickfix: set all farmIds to `1`, except those defined as `0` and `15`
      if ownerFarmId ~= FarmManager.SINGLEPLAYER_FARM_ID and ownerFarmId ~= FarmManager.SPECTATOR_FARM_ID and ownerFarmId ~= FarmManager.INVALID_FARM_ID then
        self:setOwnerFarmId( FarmManager.SINGLEPLAYER_FARM_ID, true )
      end

      --- iterate over given farmIds and set ownership as defined via config
      -- @TODO
      -- for _, farmId in ipairs( UniversalMapItemsXML.singleplayerOwnedFarmIds ) do
      --   --- we found a match!
      --   if ownerFarmId == farmId then
      --     --- this placeable belongs to the singleplayer farmer now
      --     self:setOwnerFarmId( FarmManager.SINGLEPLAYER_FARM_ID, true )
      --
      --     if UniversalMapItemsXML.enableDebugMode then
      --       g_logManager:info( "set ownerFarmId to '%s' | UniversalMapItemsXML.lua", tostring( FarmManager.SINGLEPLAYER_FARM_ID ), self.i3dFilename )
      --     end
      --
      --     --- exit the loop for this placeable, as one placeable only has one farmId associated anyways
      --     break
      --   --- if the placeable already has its farmId set to 1 but the config doesn't take over farmId 1, set it to 0
      --   -- elseif ownerFarmId == FarmManager.SINGLEPLAYER_FARM_ID and UniversalMapItemsXML.configContainsFarmId( ownerFarmId )
      --   -- @TODO check singleplayer modes / defaultFarmProperty in items.xml and farmlands.xml
      --   end
      -- end

      if UniversalMapItemsXML.enableDebugMode then
        g_logManager:info( "finished placeable '%s' (ownerFarmId: '%s') | UniversalMapItemsXML.lua", self.i3dFilename, tostring( self:getOwnerFarmId() ) )
        print( '' )
      end

      --- we're done here
      return superFunc( self )
    end
  end
)

-- addModEventListener( UniversalMapItemsXML )
