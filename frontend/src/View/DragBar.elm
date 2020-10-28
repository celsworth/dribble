module View.DragBar exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Table


view : Maybe Model.Table.ResizeOp -> Html Msg
view resizeOp =
    Maybe.map dragbar resizeOp |> Maybe.withDefault (text "")


dragbar : Model.Table.ResizeOp -> Html Msg
dragbar resizeOp =
    div (attributes resizeOp) []


attributes : Model.Table.ResizeOp -> List (Attribute Msg)
attributes resizeOp =
    [ class "dragbar"
    , style "transform" ("translate3d(" ++ String.fromFloat resizeOp.currentPosition.x ++ "px" ++ ", 0, 0)")
    ]
