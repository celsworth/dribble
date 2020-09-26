module View.DragBar exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)


view : Model -> Html Msg
view model =
    Maybe.map dragbar model.torrentAttributeResizeOp
        |> Maybe.withDefault (text "")


dragbar : TorrentAttributeResizeOp -> Html Msg
dragbar resizeOp =
    div (attributes resizeOp) []


attributes : TorrentAttributeResizeOp -> List (Attribute Msg)
attributes resizeOp =
    [ id "dragbar"
    , class "visible"
    , style "left" (String.fromFloat resizeOp.currentPosition.x ++ "px")
    ]
