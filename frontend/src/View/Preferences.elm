module View.Preferences exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (..)


view : Model -> Html Msg
view model =
    section (sectionAttributes model) (sectionContents model)


sectionAttributes : Model -> List (Attribute Msg)
sectionAttributes model =
    List.filterMap identity
        [ Just <| class "preferences window"
        , displayClass model
        ]


displayClass : Model -> Maybe (Attribute Msg)
displayClass model =
    if model.preferencesVisible then
        Just <| class "visible"

    else
        Nothing


sectionContents : Model -> List (Html Msg)
sectionContents model =
    [ div [ class "titlebar" ]
        [ i
            [ class "close-icon fas fa-times-circle"
            , onClick TogglePreferencesVisible
            ]
            []
        , strong [] [ text <| "Preferences" ]
        ]
    , units model
    ]


units : Model -> Html Msg
units model =
    div []
        [ div [] [ text "Units" ]
        , unitsInputs model
        ]


unitsInputs : Model -> Html Msg
unitsInputs _ =
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
