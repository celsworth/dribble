module View.Preferences exposing (..)

import DnDList
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (..)
import Model.Preferences as MP
import Model.Table
import Model.Torrent
import Model.Window
import View.Torrent
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
        , torrentsTableFieldset model.dnd model.config.torrentTable
        ]



-- TORRENTS TABLE FIELDSET


torrentsTableFieldset : DnDList.Model -> Model.Table.Config -> Html Msg
torrentsTableFieldset dndModel tableConfig =
    fieldset []
        [ div [ class "fieldset-header" ] [ text "Torrents Table" ]
        , div [ class "preference" ] <| torrentsTableLayout tableConfig
        , div [ class "preference" ] <| torrentsTableColumns dndModel tableConfig
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
            [ onClick <| SetPreference <| MP.Table Model.Table.Torrents MP.Layout Model.Table.Fluid
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


torrentsTableColumns : DnDList.Model -> Model.Table.Config -> List (Html Msg)
torrentsTableColumns dnd tableConfig =
    [ div [ class "preference-label" ] [ text "Columns" ]
    , torrentsTableColumnsOptions dnd tableConfig
    ]


torrentsTableColumnsOptions : DnDList.Model -> Model.Table.Config -> Html Msg
torrentsTableColumnsOptions dnd tableConfig =
    ol [] <|
        List.indexedMap (torrentsTableColumnsOption dnd) tableConfig.columns
            ++ [ ghostView dnd tableConfig ]


torrentsTableColumnsOption : DnDList.Model -> Int -> Model.Table.Column -> Html Msg
torrentsTableColumnsOption dnd index column =
    let
        (Model.Table.TorrentAttribute attribute) =
            column.attribute

        itemId =
            "dndlist-torrentsTable-" ++ Model.Torrent.attributeToKey attribute

        tableDndSystem =
            dndSystem Model.Table.Torrents
    in
    case tableDndSystem.info dnd of
        Just { dragIndex } ->
            if dragIndex /= index then
                torrentsTableColumnsOptionLi
                    (Just itemId)
                    column
                    (Just <| tableDndSystem.dropEvents index itemId)
                    Nothing

            else
                -- basically empty space to occupy the previous slot
                li [ id itemId, class "column column-moving" ] [ text "\u{00A0}" ]

        Nothing ->
            torrentsTableColumnsOptionLi
                (Just itemId)
                column
                (Just <| tableDndSystem.dragEvents index itemId)
                Nothing


torrentsTableColumnsOptionLi itemId column dndEvents dndStyles =
    let
        (Model.Table.TorrentAttribute attribute) =
            column.attribute

        visibility =
            if column.visible then
                "column-visible"

            else
                "column-hidden"

        idAttribute =
            Maybe.map id itemId

        liStyles =
            List.filterMap identity [ Just (class "column"), Just (class visibility) ]
                ++ Maybe.withDefault [] dndStyles

        divAttributes =
            List.filterMap identity [ Just (class "draggable"), idAttribute ]
                ++ Maybe.withDefault [] dndEvents
    in
    li liStyles
        [ i [ onClick (ToggleTorrentAttributeVisibility attribute), class "fas fa-eye" ] []
        , div divAttributes
            [ i [ class "fas fa-arrows-alt-v" ] []
            , text <| View.Torrent.attributeToString attribute
            ]
        ]


ghostView : DnDList.Model -> Model.Table.Config -> Html Msg
ghostView dnd tableConfig =
    let
        items =
            tableConfig.columns

        tableDndSystem =
            dndSystem Model.Table.Torrents

        maybeDragItem =
            tableDndSystem.info dnd
                |> Maybe.andThen
                    (\{ dragIndex } ->
                        items |> List.drop dragIndex |> List.head
                    )
    in
    case maybeDragItem of
        Just column ->
            torrentsTableColumnsOptionLi Nothing column Nothing (Just <| tableDndSystem.ghostStyles dnd)

        Nothing ->
            text ""



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
