module Update.SetContextMenu exposing (update)

import Model exposing (..)
import Model.ContextMenu
import Utils.Mouse as Mouse


update : Model.ContextMenu.For -> Mouse.Event -> Model -> ( Model, Cmd Msg )
update contextMenuFor { clientPos } model =
    model
        |> setContextMenu (Just { for = contextMenuFor, position = clientPos })
        |> noCmd
