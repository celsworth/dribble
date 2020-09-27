module View.Preferences exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (..)


view : Model -> Html Msg
view model =
    section (sectionAttributes model)
        [ h1 []
            [ text <| "Prefs Window" ]
        ]


sectionAttributes : Model -> List (Attribute Msg)
sectionAttributes model =
    List.filterMap identity <|
        [ Just <| id "preferences"
        , displayStyle model
        ]


displayStyle : Model -> Maybe (Attribute Msg)
displayStyle model =
    if model.preferencesVisible then
        Just <| class "visible"

    else
        Nothing
