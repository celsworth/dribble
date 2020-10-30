module View.TorrentTable exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse as Mouse
import Html.Keyed as Keyed
import Html.Lazy
import List
import Model exposing (..)
import Model.Attribute
import Model.Config
import Model.ContextMenu exposing (ContextMenu, For(..))
import Model.MousePosition
import Model.Sort
import Model.Table
import Model.Torrent exposing (Torrent, TorrentsByHash)
import Model.TorrentFilter exposing (TorrentFilter)
import Model.TorrentTable exposing (Column, Config)
import Time
import View.DragBar
import View.Table
import View.Torrent
import View.Utils.ContextMenu
import View.Utils.TorrentStatusIcon


view : Model -> Html Msg
view model =
    if List.isEmpty model.sortedTorrents then
        section [ class "torrent-table loading" ]
            [ i [ class "fas fa-spinner fa-pulse" ] [] ]

    else
        section [ class "torrent-table" ]
            [ table [ class <| View.Table.layoutToClass model.config.torrentTable.layout ]
                [ Html.Lazy.lazy View.DragBar.view model.resizeOp
                , Html.Lazy.lazy2 header model.config model.config.torrentTable
                , Html.Lazy.lazy7 body
                    model.currentTime
                    model.config.humanise
                    model.config.torrentTable
                    model.torrentFilter
                    model.torrentsByHash
                    model.sortedTorrents
                    model.selectedTorrentHash
                ]
            , maybeHeaderContextMenu model.config.torrentTable model.contextMenu
            ]


header : Model.Config.Config -> Config -> Html Msg
header config tableConfig =
    let
        visibleOrder =
            List.filter .visible tableConfig.columns
    in
    thead []
        [ tr []
            (List.map (headerCell config tableConfig) visibleOrder)
        ]


maybeHeaderContextMenu : Config -> Maybe ContextMenu -> Html Msg
maybeHeaderContextMenu tableConfig contextMenu =
    Maybe.withDefault (text "") <|
        Maybe.map (headerContextMenu tableConfig) contextMenu


headerContextMenu : Config -> ContextMenu -> Html Msg
headerContextMenu tableConfig contextMenu =
    case contextMenu.for of
        TorrentTableColumn column ->
            View.Utils.ContextMenu.view contextMenu
                [ ul [] <|
                    [ headerContextMenuAutoWidth column, hr [] [] ]
                        ++ List.map headerContextMenuColumnRow tableConfig.columns
                ]

        _ ->
            text ""


headerContextMenuAutoWidth : Column -> Html Msg
headerContextMenuAutoWidth column =
    li
        [ onClick <| SetColumnAutoWidth <| Model.Attribute.TorrentAttribute column.attribute ]
        [ text <| "Auto-Fit " ++ Model.Torrent.attributeToString column.attribute ]


headerContextMenuColumnRow : Column -> Html Msg
headerContextMenuColumnRow column =
    let
        ( i_class, li_class ) =
            if column.visible then
                ( "fa-check", "" )

            else
                ( "", "disabled" )
    in
    li
        [ onClick <| ToggleAttributeVisibility <| Model.Attribute.TorrentAttribute column.attribute
        , class li_class
        ]
        [ i [ class <| "fa-fw fas " ++ i_class ] []
        , text <| Model.Torrent.attributeToString column.attribute
        ]


headerCell : Model.Config.Config -> Config -> Column -> Html Msg
headerCell config tableConfig column =
    let
        attrString =
            Model.Torrent.attributeToTableHeaderString column.attribute

        maybeResizeDiv =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    Just <| div (headerCellResizeHandleAttributes column) []

                Model.Table.Fluid ->
                    Nothing
    in
    th (headerCellAttributes config column)
        (List.filterMap identity
            [ Just <|
                div (headerCellContentDivAttributes tableConfig column)
                    [ text attrString ]
            , maybeResizeDiv
            ]
        )


headerCellAttributes : Model.Config.Config -> Column -> List (Attribute Msg)
headerCellAttributes config column =
    let
        contextMenuHandler =
            if config.enableContextMenus then
                Just <|
                    Mouse.onContextMenu
                        (\e ->
                            DisplayContextMenu
                                (Model.ContextMenu.TorrentTableColumn column)
                                (Model.MousePosition.reconstructClientPos e)
                                e.button
                                e.keys
                        )

            else
                Nothing
    in
    List.filterMap identity
        [ headerCellIdAttribute column
        , cellTextAlign column
        , headerCellSortClass config.sortBy column
        , contextMenuHandler
        ]


headerCellIdAttribute : Column -> Maybe (Attribute Msg)
headerCellIdAttribute column =
    Just <| id (Model.Torrent.attributeToTableHeaderId column.attribute)


headerCellSortClass : Model.Torrent.Sort -> Column -> Maybe (Attribute Msg)
headerCellSortClass sortBy column =
    let
        (Model.Torrent.SortBy currentSortAttribute currentSortDirection) =
            sortBy
    in
    if currentSortAttribute == column.attribute then
        case currentSortDirection of
            Model.Sort.Asc ->
                Just <| class "sorted ascending"

            Model.Sort.Desc ->
                Just <| class "sorted descending"

    else
        Nothing


headerCellContentDivAttributes : Config -> Column -> List (Attribute Msg)
headerCellContentDivAttributes tableConfig column =
    let
        maybeWidthAttr =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    View.Table.thWidthAttribute column

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity
        [ maybeWidthAttr
        , Just <| onClick (SetSortBy (Model.Attribute.TorrentAttribute column.attribute))
        ]


headerCellResizeHandleAttributes : Column -> List (Attribute Msg)
headerCellResizeHandleAttributes column =
    [ class "resize-handle"
    , Mouse.onDown (\e -> MouseDown (Model.Attribute.TorrentAttribute column.attribute) (Model.MousePosition.reconstructClientPos e) e.button e.keys)
    ]



-- BODY


body : Time.Posix -> Model.Config.Humanise -> Config -> TorrentFilter -> TorrentsByHash -> List String -> Maybe String -> Html Msg
body currentTime humanise tableConfig torrentFilter torrentsByHash sortedTorrents selectedTorrentHash =
    Keyed.node "tbody" [] <|
        List.filterMap identity
            (List.map
                (keyedRow currentTime
                    humanise
                    tableConfig
                    torrentFilter
                    torrentsByHash
                    selectedTorrentHash
                )
                sortedTorrents
            )


keyedRow : Time.Posix -> Model.Config.Humanise -> Config -> TorrentFilter -> TorrentsByHash -> Maybe String -> String -> Maybe ( String, Html Msg )
keyedRow currentTime humanise tableConfig torrentFilter torrentsByHash selectedTorrentHash hash =
    Maybe.map
        (\torrent ->
            ( hash
            , lazyRow
                currentTime
                humanise
                tableConfig
                (Just torrentFilter)
                selectedTorrentHash
                torrent
            )
        )
        (Dict.get hash torrentsByHash)


lazyRow : Time.Posix -> Model.Config.Humanise -> Config -> Maybe TorrentFilter -> Maybe String -> Torrent -> Html Msg
lazyRow currentTime humanise tableConfig torrentFilter selectedTorrentHash torrent =
    let
        matches =
            Maybe.map (Model.TorrentFilter.torrentMatches currentTime torrent) torrentFilter
                |> Maybe.withDefault True

        rowIsSelected =
            Maybe.map ((==) torrent.hash) selectedTorrentHash
                |> Maybe.withDefault False
    in
    if matches then
        -- pass in as little as possible so lazy works as well as possible
        Html.Lazy.lazy4 row humanise tableConfig rowIsSelected torrent

    else
        text ""


row : Model.Config.Humanise -> Config -> Bool -> Torrent -> Html Msg
row humanise tableConfig rowIsSelected torrent =
    let
        {-
           _ =
               Debug.log "rendering:" torrent
        -}
        visibleColumns =
            List.filter .visible tableConfig.columns

        trClass =
            if rowIsSelected then
                Just <| class "selected"

            else
                Nothing
    in
    tr
        (List.filterMap identity
            [ trClass
            , Just <| onClick <| TorrentRowSelected torrent.hash
            ]
        )
        (List.map (cell tableConfig humanise torrent) visibleColumns)


cell : Config -> Model.Config.Humanise -> Torrent -> Column -> Html Msg
cell tableConfig humanise torrent column =
    td []
        [ div (cellAttributes tableConfig column)
            [ cellContent humanise torrent column ]
        ]


cellAttributes : Config -> Column -> List (Attribute Msg)
cellAttributes tableConfig column =
    let
        maybeWidthAttr =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    View.Table.tdWidthAttribute column

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity [ maybeWidthAttr, cellTextAlign column ]


cellTextAlign : Column -> Maybe (Attribute Msg)
cellTextAlign column =
    Maybe.map class (View.Torrent.attributeTextAlignment column.attribute)


cellContent : Model.Config.Humanise -> Torrent -> Column -> Html Msg
cellContent humanise torrent column =
    case column.attribute of
        Model.Torrent.Status ->
            View.Utils.TorrentStatusIcon.view torrent.status

        Model.Torrent.DonePercent ->
            View.Table.donePercentCell torrent.donePercent

        torrentAttribute ->
            View.Torrent.attributeAccessor humanise torrent torrentAttribute
