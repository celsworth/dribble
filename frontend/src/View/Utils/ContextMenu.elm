module View.Utils.ContextMenu exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.ContextMenu exposing (ContextMenu, Position)


view : ContextMenu -> List (Html Msg) -> Html Msg
view contextMenu content =
    node "context-menu" (attributes contextMenu) content


attributes : ContextMenu -> List (Attribute Msg)
attributes contextMenu =
    let
        { position } =
            contextMenu
    in
    class "context-menu"
        :: positionAttributes position


positionAttributes : Position -> List (Attribute Msg)
positionAttributes position =
    [ style "top" <| String.fromFloat position.y ++ "px"
    , style "left" <| String.fromFloat position.x ++ "px"
    ]
