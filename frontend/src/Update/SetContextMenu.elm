module Update.SetContextMenu exposing (update)

import Html.Events.Extra.Mouse as Mouse
import Model exposing (..)
import Model.ContextMenu
import Model.MousePosition exposing (MousePosition)


update : Model.ContextMenu.For -> MousePosition -> Mouse.Button -> Mouse.Keys -> Model -> ( Model, Cmd Msg )
update contextMenuFor pos _ _ model =
    model
        |> setContextMenu (Just { for = contextMenuFor, position = pos })
        |> noCmd
