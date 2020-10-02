module Update.WindowResized exposing (update)

import Json.Decode as JD
import Model exposing (..)
import Model.Config exposing (Config)
import Model.Window


update : Result JD.Error Model.Window.ResizeDetails -> Model -> ( Model, Cmd Msg )
update result model =
    case result of
        Ok resizeDetails ->
            handleSuccess resizeDetails model

        Err _ ->
            -- this JSON is from our own javascript..
            -- so this should never happen
            model |> addCmd Cmd.none


handleSuccess : Model.Window.ResizeDetails -> Model -> ( Model, Cmd Msg )
handleSuccess resizeDetails model =
    let
        windowConfig =
            getWindowConfig model.config resizeDetails

        newWindowConfig =
            { windowConfig
                | width = resizeDetails.width
                , height = resizeDetails.height
            }

        setter =
            configSetter resizeDetails

        newConfig =
            model.config |> setter newWindowConfig
    in
    model
        |> setConfig newConfig
        |> addCmd Cmd.none


getWindowConfig : Config -> Model.Window.ResizeDetails -> Model.Window.Config
getWindowConfig config resizeDetails =
    case Model.Window.idToType resizeDetails.id of
        Model.Window.Preferences ->
            config.preferences

        Model.Window.Logs ->
            config.logs


configSetter : Model.Window.ResizeDetails -> Model.Window.Config -> Model.Config.Config -> Config
configSetter resizeDetails =
    case Model.Window.idToType resizeDetails.id of
        Model.Window.Preferences ->
            Model.Config.setPreferences

        Model.Window.Logs ->
            Model.Config.setLogs
