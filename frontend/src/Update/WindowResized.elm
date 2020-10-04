module Update.WindowResized exposing (update)

import Json.Decode as JD
import Model exposing (..)
import Model.Window
import Update.Shared.ConfigHelpers exposing (getWindowConfig, windowConfigSetter)


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
        windowType =
            Model.Window.idToType resizeDetails.id

        windowConfig =
            getWindowConfig model.config windowType

        newWindowConfig =
            { windowConfig
                | width = resizeDetails.width
                , height = resizeDetails.height
            }

        setter =
            windowConfigSetter windowType

        newConfig =
            model.config |> setter newWindowConfig
    in
    model
        |> setConfig newConfig
        |> addCmd Cmd.none
