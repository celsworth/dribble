module View.Preferences exposing (..)

import DnDList
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D
import Model exposing (..)
import Model.Attribute
import Model.Preferences as MP
import Model.Table
import Model.Torrent
import Model.TorrentTable
import Model.Window
import View.Utils.Events
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


torrentsTableFieldset : DnDList.Model -> Model.TorrentTable.Config -> Html Msg
torrentsTableFieldset dndModel tableConfig =
    fieldset []
        [ div [ class "fieldset-header" ] [ text "Torrents Table" ]
        , div [ class "preference" ] <| torrentsTableLayout tableConfig
        , div [ class "preference" ] <| torrentsTableColumns dndModel tableConfig
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


torrentsTableColumns : DnDList.Model -> Model.TorrentTable.Config -> List (Html Msg)
torrentsTableColumns dnd tableConfig =
    [ div [ class "preference-label" ] [ text "Columns" ]
    , torrentsTableColumnsOptions dnd tableConfig
    ]


torrentsTableColumnsOptions : DnDList.Model -> Model.TorrentTable.Config -> Html Msg
torrentsTableColumnsOptions dnd tableConfig =
    ol [] <|
        List.indexedMap (torrentsTableColumnsOption dnd) tableConfig.columns
            ++ [ ghostView dnd tableConfig ]


torrentsTableColumnsOption : DnDList.Model -> Int -> Model.TorrentTable.Column -> Html Msg
torrentsTableColumnsOption dnd index column =
    let
        attribute =
            column.attribute

        itemId =
            "dndlist-torrentsTable-" ++ Model.Torrent.attributeToKey attribute

        tableDndSystem =
            dndSystemTorrent Model.Table.Torrents
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


torrentsTableColumnsOptionLi : Maybe String -> Model.TorrentTable.Column -> Maybe (List (Attribute Msg)) -> Maybe (List (Attribute Msg)) -> Html Msg
torrentsTableColumnsOptionLi itemId column dndEvents dndStyles =
    let
        attribute =
            column.attribute

        visibility =
            if column.visible then
                "column-visible"

            else
                "column-hidden"

        liAttributes =
            List.filterMap identity
                [ Just (class "column")
                , Just (class visibility)
                , Just <| onClick (ToggleAttributeVisibility (Model.Attribute.TorrentAttribute attribute))
                , Maybe.map id itemId
                ]
                ++ Maybe.withDefault [] dndStyles
                ++ Maybe.withDefault [] dndEvents

        divAttributes =
            List.filterMap identity
                [ Just <| View.Utils.Events.stopPropagation
                , Just <| style "flex-grow" "1"
                ]
    in
    li liAttributes
        [ div divAttributes
            [ text <| Model.Torrent.attributeToString attribute ]
        , i [ class "draggable fas fa-grip-lines" ] []
        ]


ghostView : DnDList.Model -> Model.TorrentTable.Config -> Html Msg
ghostView dnd tableConfig =
    let
        items =
            tableConfig.columns

        tableDndSystem =
            dndSystemTorrent Model.Table.Torrents

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
