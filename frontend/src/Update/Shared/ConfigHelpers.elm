module Update.Shared.ConfigHelpers exposing (..)

import Model exposing (..)
import Model.Config exposing (Config)
import Model.Table
import Model.Window



-- TABLES


getTableConfig : Config -> Model.Table.Type -> Model.Table.Config
getTableConfig config tableType =
    case tableType of
        Model.Table.Torrents ->
            config.torrentTable

        Model.Table.Files ->
            config.fileTable

        Model.Table.Peers ->
            config.peerTable


tableConfigSetter : Model.Table.Type -> Model.Table.Config -> Config -> Config
tableConfigSetter tableType =
    case tableType of
        Model.Table.Torrents ->
            Model.Config.setTorrentTable

        Model.Table.Files ->
            Model.Config.setFileTable

        Model.Table.Peers ->
            Model.Config.setPeerTable



-- WINDOWS


getWindowConfig : Config -> Model.Window.Type -> Model.Window.Config
getWindowConfig config windowType =
    case windowType of
        Model.Window.Preferences ->
            config.preferences

        Model.Window.Logs ->
            config.logs


windowConfigSetter : Model.Window.Type -> Model.Window.Config -> Config -> Config
windowConfigSetter windowType =
    case windowType of
        Model.Window.Preferences ->
            Model.Config.setPreferences

        Model.Window.Logs ->
            Model.Config.setLogs
