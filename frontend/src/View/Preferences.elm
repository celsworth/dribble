module View.Preferences exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (..)
import Model.Preferences as MP
import Model.Table
import Model.Window
import View.Torrent
import View.Window


view : Model -> Html Msg
view model =
    section (sectionAttributes model) (sectionContents model)


sectionAttributes : Model -> List (Attribute Msg)
sectionAttributes model =
    let
        windowConfig =
            model.config.preferences
    in
    List.filterMap identity
        [ Just <| id "preferences"
        , Just <| class "preferences window"
        , Just <| style "width" (View.Window.width windowConfig)
        , Just <| style "height" (View.Window.height windowConfig)
        , displayClass windowConfig
        ]


displayClass : Model.Window.Config -> Maybe (Attribute Msg)
displayClass windowConfig =
    if windowConfig.visible then
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
    , torrentsTableFieldset model.config.torrentTable
    ]



-- TORRENTS TABLE FIELDSET


torrentsTableFieldset : Model.Table.Config -> Html Msg
torrentsTableFieldset tableConfig =
    fieldset []
        [ div [ class "fieldset-header" ] [ text "Torrents Table" ]
        , div [ class "preference" ] <| torrentsTableLayout tableConfig
        , div [ class "preference" ] <| torrentsTableColumns tableConfig
        ]


torrentsTableLayout : Model.Table.Config -> List (Html Msg)
torrentsTableLayout tableConfig =
    [ div [ class "preference-label" ] [ text "Layout" ]
    , torrentsTableLayoutOptions tableConfig
    ]


torrentsTableLayoutOptions : Model.Table.Config -> Html Msg
torrentsTableLayoutOptions tableConfig =
    div []
        [ div
            [ onClick <| SetPreference <| MP.Table Model.Table.Torrents MP.Layout Model.Table.Fixed
            , class "preference-option"
            ]
            [ input
                [ name "torrent-table-layout"
                , type_ "radio"
                ]
                []
            , div [ class "preference-text" ]
                [ span [ class "radio-label" ] [ text "Fixed" ]
                , small [] [ tableFixedText ]
                ]
            ]
        , div
            [ onClick <| SetPreference <| MP.Table Model.Table.Torrents MP.Layout Model.Table.Fluid
            , class "preference-option"
            ]
            [ input [ name "torrent-table-layout", type_ "radio" ] []
            , div [ class "preference-text" ]
                [ span [ class "radio-label" ] [ text "Fluid" ]
                , small [] [ tableFixedText ]
                ]
            ]
        ]


tableFixedText : Html Msg
tableFixedText =
    text "Columns use the widths you set, without any dynamic reflowing."


torrentsTableColumns : Model.Table.Config -> List (Html Msg)
torrentsTableColumns tableConfig =
    [ div [ class "preference-label" ] [ text "Columns" ]
    , torrentsTableColumnsOptions tableConfig
    ]


torrentsTableColumnsOptions : Model.Table.Config -> Html Msg
torrentsTableColumnsOptions tableConfig =
    ol [] <|
        List.map torrentsTableColumnsOption tableConfig.columns


torrentsTableColumnsOption : Model.Table.Column -> Html Msg
torrentsTableColumnsOption column =
    let
        (Model.Table.TorrentAttribute attribute) =
            column.attribute

        visibility =
            if column.visible then
                "column-visible"

            else
                "column-hidden"
    in
    li [ class "column", class visibility ]
        [ i [ onClick (ToggleTorrentAttributeVisibility attribute), class "fas fa-eye" ]
            []
        , text <| View.Torrent.attributeToString attribute
        ]



-- TMP


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
