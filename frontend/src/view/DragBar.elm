module View.DragBar exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)


view : Model -> Html Msg
view model =
    div (attributes model) []


attributes : Model -> List (Attribute Msg)
attributes model =
    case model.torrentAttributeResizeOp of
        Just resizeOp ->
            attributesIfResizing resizeOp

        _ ->
            []


attributesIfResizing : TorrentAttributeResizeOp -> List (Attribute Msg)
attributesIfResizing resizeOp =
    [ id "dragbar"
    , class "visible"
    , style "left" (String.fromFloat resizeOp.currentPosition.x ++ "px")
    ]
