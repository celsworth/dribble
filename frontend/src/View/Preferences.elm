module View.Preferences exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (..)


view : Model -> Html Msg
view model =
    section (sectionAttributes model)
        [ h1 []
            [ text <| "Preferences" ]
        , div []
            [ units model ]
        ]


sectionAttributes : Model -> List (Attribute Msg)
sectionAttributes model =
    List.filterMap identity <|
        [ Just <| id "preferences"
        , Just <| class "form"
        , displayStyle model
        ]


displayStyle : Model -> Maybe (Attribute Msg)
displayStyle model =
    if model.preferencesVisible then
        Just <| class "visible"

    else
        Nothing


units : Model -> Html Msg
units model =
    div []
        [ div [] [ text "Units" ]
        , unitsInputs model
        ]


unitsInputs : Model -> Html Msg
unitsInputs model =
    div [ class "control-group" ]
        [ label [ class "radio" ]
            [ input [ type_ "radio" ] []
            , text "Decimal / SI (kB/s)"
            ]
        , label [ class "radio" ]
            [ input [ type_ "radio" ] []
            , text "Binary (KiB/s)"
            ]
        ]
