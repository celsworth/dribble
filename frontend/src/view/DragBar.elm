module View.DragBar exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)


view : Model -> Html Msg
view model =
    div (attributes model) []


attributes : Model -> List (Attribute Msg)
attributes model =
    let
        ( x, y ) =
            model.mousePosition

        kls =
            if model.dragging /= Nothing then
                Just <| class "visible"

            else
                Nothing
    in
    List.filterMap identity <|
        [ Just <| id "dragbar"
        , kls
        , Just <| style "left" (String.fromFloat x ++ "px")
        ]
