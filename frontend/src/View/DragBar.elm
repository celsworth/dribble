module View.DragBar exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Table


view : Model -> Html Msg
view model =
    Maybe.map dragbar model.torrentAttributeResizeOp
        |> Maybe.withDefault (text "")


dragbar : Model.Table.ResizeOp -> Html Msg
dragbar resizeOp =
    div (attributes resizeOp) []


attributes : Model.Table.ResizeOp -> List (Attribute Msg)
attributes resizeOp =
    [ id "dragbar"
    , class "visible"
    , style "left" (String.fromFloat resizeOp.currentPosition.x ++ "px")
    ]
