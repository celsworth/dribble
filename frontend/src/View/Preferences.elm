module View.Preferences exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (..)
import Model.Preferences as MP
import Model.Table
import Model.TorrentTable
import Model.Window
import View.Window


view : Model -> Html Msg
view model =
    -- need to add the section to the DOM even when hidden,
    -- so ResizeObserver can find it
    section (sectionAttributes model.config.preferences)
        -- however can avoid rendering any invisible content
        [ if model.config.preferences.visible then
            sectionContents model

          else
            text ""
        ]


sectionAttributes : Model.Window.Config -> List (Attribute Msg)
sectionAttributes windowConfig =
    let
        displayClass =
            if windowConfig.visible then
                Just <| class "visible"

            else
                Nothing
    in
    List.filterMap identity
        [ Just <| id "preferences"
        , Just <| class "preferences window"
        , Just <| style "width" (View.Window.width windowConfig)
        , Just <| style "height" (View.Window.height windowConfig)
        , displayClass
        ]


sectionContents : Model -> Html Msg
sectionContents model =
    div []
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


torrentsTableFieldset : Model.TorrentTable.Config -> Html Msg
torrentsTableFieldset tableConfig =
    fieldset []
        [ div [ class "fieldset-header" ] [ text "Torrents Table" ]
        , div [ class "preference" ] <| torrentsTableLayout tableConfig
        ]


torrentsTableLayout : Model.TorrentTable.Config -> List (Html Msg)
torrentsTableLayout tableConfig =
    [ div [ class "preference-label" ] [ text "Layout" ]
    , torrentsTableLayoutOptions tableConfig
    ]


torrentsTableLayoutOptions : Model.TorrentTable.Config -> Html Msg
torrentsTableLayoutOptions tableConfig =
    div []
        [ div
            [ onClick <| SetPreference <| MP.Table Model.Table.Torrents (MP.Layout Model.Table.Fixed)
            , class "preference-option"
            ]
            [ input
                [ name "torrent-table-layout"
                , checked (tableConfig.layout == Model.Table.Fixed)
                , type_ "radio"
                ]
                []
            , div [ class "preference-text" ]
                [ span [ class "radio-label" ] [ text "Fixed" ]
                , small [] [ text "Columns use the widths you set, without any dynamic resizing." ]
                ]
            ]
        , div
            [ onClick <| SetPreference <| MP.Table Model.Table.Torrents (MP.Layout Model.Table.Fluid)
            , class "preference-option"
            ]
            [ input
                [ name "torrent-table-layout"
                , checked (tableConfig.layout == Model.Table.Fluid)
                , type_ "radio"
                ]
                []
            , div [ class "preference-text" ]
                [ span [ class "radio-label" ] [ text "Fluid" ]
                , small [] [ text "Columns size themselves dynamically according to content." ]
                ]
            ]
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
