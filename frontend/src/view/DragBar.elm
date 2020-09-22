module View.DragBar exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)


view : Model -> Html Msg
view model =
    case model.torrentAttributeResizeOp of
        Just resizeOp ->
            div (attributes resizeOp) []

        _ ->
            text ""


attributes : TorrentAttributeResizeOp -> List (Attribute Msg)
attributes resizeOp =
    [ id "dragbar"
    , class "visible"
    , style "left" (String.fromFloat resizeOp.currentPosition.x ++ "px")
    ]
