module Update.ToggleWindowVisible exposing (update)

import Model exposing (..)
import Model.Config exposing (Config)
import Model.Window


update : Model.Window.Type -> Model -> ( Model, Cmd Msg )
update windowType model =
    let
        windowConfig =
            getWindowConfig model.config windowType

        newWindowConfig =
            windowConfig |> Model.Window.toggleVisible

        newConfig =
            model.config
                |> configSetter windowType newWindowConfig
    in
    model
        |> setConfig newConfig
        |> setHamburgerMenuVisible False
        |> addCmd Cmd.none


getWindowConfig : Config -> Model.Window.Type -> Model.Window.Config
getWindowConfig config windowType =
    case windowType of
        Model.Window.Preferences ->
            config.preferences

        Model.Window.Logs ->
            config.logs


configSetter : Model.Window.Type -> Model.Window.Config -> Config -> Config
configSetter windowType =
    case windowType of
        Model.Window.Preferences ->
            Model.Config.setPreferences

        Model.Window.Logs ->
            Model.Config.setLogs
