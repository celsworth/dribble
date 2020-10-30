module View.Table exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Sort exposing (SortDirection(..))
import Model.Table
import Round


type alias Column a =
    { a
        | auto : Bool
        , width : Float
    }


layoutToClass : Model.Table.Layout -> String
layoutToClass layout =
    case layout of
        Model.Table.Fluid ->
            "fluid"

        Model.Table.Fixed ->
            "fixed"



-- CONTENT CELL HELPERS


donePercentCell : Float -> Html Msg
donePercentCell donePercent =
    let
        dp =
            if donePercent == 100 then
                0

            else
                1
    in
    div [ class "progress-container" ]
        [ progress
            [ class "progress"
            , Html.Attributes.max "100"
            , Html.Attributes.value <| Round.round 0 donePercent
            ]
            []
        , span [ class "progress-text" ]
            [ text (Round.round dp donePercent ++ "%") ]
        ]



{-
   WIDTH HELPERS

   this complication is because the width stored in columnWidths
   includes padding and borders. To set the proper size for the
   internal div, we need to subtract some:

   For th columns, that amounts to 16px:
     1 + 1px borders
     4px left padding
     10px right padding

   For td, there are no borders, so its just 2*4px padding to remove
-}


thWidthAttribute : Column a -> Maybe (Attribute Msg)
thWidthAttribute column =
    widthAttribute column 16


tdWidthAttribute : Column a -> Maybe (Attribute Msg)
tdWidthAttribute column =
    widthAttribute column 8


widthAttribute : Column a -> Float -> Maybe (Attribute Msg)
widthAttribute column subtract =
    if column.auto then
        Nothing

    else
        Just <| style "width" (Round.round 0 (column.width - subtract) ++ "px")
