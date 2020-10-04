module Update.ToggleWindowVisible exposing (update)

import Model exposing (..)
import Model.Window
import Update.Shared.ConfigHelpers exposing (getWindowConfig, windowConfigSetter)


update : Model.Window.Type -> Model -> ( Model, Cmd Msg )
update windowType model =
    let
        windowConfig =
            getWindowConfig model.config windowType

        newWindowConfig =
            windowConfig |> Model.Window.toggleVisible

        newConfig =
            model.config
                |> windowConfigSetter windowType newWindowConfig
    in
    model
        |> setConfig newConfig
        |> setHamburgerMenuVisible False
        |> addCmd Cmd.none
