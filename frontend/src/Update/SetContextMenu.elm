module Update.SetContextMenu exposing (update)

import Model exposing (..)
import Model.ContextMenu
import Utils.Mouse as Mouse


update : Model.ContextMenu.For -> Mouse.Position -> Mouse.Button -> Mouse.Keys -> Model -> ( Model, Cmd Msg )
update contextMenuFor pos _ _ model =
    model
        |> setContextMenu (Just { for = contextMenuFor, position = pos })
        |> noCmd
