module View.Utils.ContextMenu exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.ContextMenu exposing (ContextMenu)
import Utils.Mouse as Mouse


view : ContextMenu -> List (Html Msg) -> Html Msg
view contextMenu content =
    node "context-menu" (attributes contextMenu) content


attributes : ContextMenu -> List (Attribute Msg)
attributes contextMenu =
    class "context-menu"
        :: positionAttributes contextMenu.position


positionAttributes : Mouse.Position -> List (Attribute Msg)
positionAttributes position =
    [ style "top" <| String.fromFloat position.y ++ "px"
    , style "left" <| String.fromFloat position.x ++ "px"
    ]
