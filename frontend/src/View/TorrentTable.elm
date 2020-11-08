module View.TorrentTable exposing (view)

import Dict
import DnDList
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse as Mouse
import Html.Keyed as Keyed
import Html.Lazy
import Json.Decode as JD
import List
import Model exposing (..)
import Model.Attribute
import Model.Config
import Model.ContextMenu exposing (ContextMenu, For(..))
import Model.MousePosition
import Model.Sort
import Model.Table
import Model.Torrent exposing (Torrent, TorrentsByHash)
import Model.TorrentTable exposing (Column, Config)
import Round
import Time
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
        section
            [ Html.Events.on "scroll" scrollDecoder
            , class "torrent-table"
            ]
            [ table [ class <| View.Table.layoutToClass model.config.torrentTable.layout ]
                [ Html.Lazy.lazy2 header model.config model.config.torrentTable
                , Html.Lazy.lazy6 body
                    model.top
                    model.config.humanise
                    model.config.torrentTable
                    model.torrentsByHash
                    model.filteredTorrents
                    model.selectedTorrentHash
                ]
            , Html.Lazy.lazy3 maybeHeaderContextMenu
                model.dnd
                model.config.torrentTable
                model.contextMenu
            ]


scrollDecoder : JD.Decoder Msg
scrollDecoder =
    JD.succeed ScrollEvent
        |> JD.map2 (|>) (JD.at [ "target", "scrollTop" ] JD.float)
        |> JD.map2 (|>) (JD.at [ "target", "scrollHeight" ] JD.float)
        |> JD.map2 (|>) (JD.at [ "target", "scrollLeft" ] JD.float)
        |> JD.map2 (|>) (JD.at [ "target", "scrollWidth" ] JD.float)
        |> JD.map Scroll


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


maybeHeaderContextMenu : DnDList.Model -> Config -> Maybe ContextMenu -> Html Msg
maybeHeaderContextMenu dnd tableConfig contextMenu =
    Maybe.withDefault (text "") <|
        Maybe.map (headerContextMenu dnd tableConfig) contextMenu


headerContextMenu : DnDList.Model -> Config -> ContextMenu -> Html Msg
headerContextMenu dnd tableConfig contextMenu =
    case contextMenu.for of
        TorrentTableColumn column ->
            View.Utils.ContextMenu.view contextMenu
                [ ul [] <|
                    [ headerContextMenuAutoWidth column, hr [] [] ]
                        ++ List.indexedMap (headerContextMenuAttributeRow dnd) tableConfig.columns
                        ++ [ headerContextMenuAttributeRowGhostLi dnd tableConfig.columns ]
                ]

        _ ->
            text ""


headerContextMenuAutoWidth : Column -> Html Msg
headerContextMenuAutoWidth column =
    View.Table.headerContextMenuAutoWidth
        (Model.Attribute.TorrentAttribute column.attribute)
        ("Auto-Fit " ++ Model.Torrent.attributeToString column.attribute)


headerContextMenuAttributeRow : DnDList.Model -> Int -> Column -> Html Msg
headerContextMenuAttributeRow dnd index column =
    View.Table.headerContextMenuAttributeRow
        (Model.TorrentTable.dndSystem DnDMsg)
        dnd
        index
        ("dndlist-torrentTable-" ++ Model.Torrent.attributeToKey column.attribute)
        column
        (Model.Attribute.TorrentAttribute column.attribute)
        (Model.Torrent.attributeToString column.attribute)


headerContextMenuAttributeRowGhostLi : DnDList.Model -> List Column -> Html Msg
headerContextMenuAttributeRowGhostLi dnd columns =
    let
        dndSystem =
            Model.TorrentTable.dndSystem DnDMsg

        maybeDragItem =
            dndSystem.info dnd
                |> Maybe.andThen
                    (\{ dragIndex } ->
                        columns |> List.drop dragIndex |> List.head
                    )
    in
    case maybeDragItem of
        Just column ->
            View.Table.headerContextMenuAttributeRowLi
                Nothing
                column
                (Model.Attribute.TorrentAttribute column.attribute)
                (Model.Torrent.attributeToString column.attribute)
                Nothing
                (Just <| dndSystem.ghostStyles dnd)

        Nothing ->
            text ""


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
    List.filterMap identity
        [ headerCellIdAttribute column
        , cellTextAlign column
        , headerCellSortClass config.sortBy column
        , View.Table.maybeHeaderContextMenuHandler config (Model.ContextMenu.TorrentTableColumn column)
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


body : Float -> Model.Config.Humanise -> Config -> TorrentsByHash -> List String -> Maybe String -> Html Msg
body top humanise tableConfig torrentsByHash filteredTorrents selectedTorrentHash =
    let
        rowHeight =
            -- FIXME assumption
            21

        dropTop =
            Basics.max (Round.truncate (top / rowHeight) - 30) 0

        take =
            -- FIXME should be tied to window heihgt
            80

        visibleTorrents =
            filteredTorrents
                |> List.drop dropTop
                |> List.take take

        topSpacePx =
            dropTop * rowHeight

        bottomSpacePx =
            rowHeight * (List.length filteredTorrents - List.length visibleTorrents - dropTop)
    in
    Keyed.node "tbody" [] <|
        List.filterMap identity <|
            [ View.Table.heightRow "topSpace" topSpacePx ]
                ++ List.map
                    (keyedRow
                        humanise
                        tableConfig
                        torrentsByHash
                        selectedTorrentHash
                    )
                    visibleTorrents
                ++ [ View.Table.heightRow "bottomSpace" bottomSpacePx ]


keyedRow : Model.Config.Humanise -> Config -> TorrentsByHash -> Maybe String -> String -> Maybe ( String, Html Msg )
keyedRow humanise tableConfig torrentsByHash selectedTorrentHash hash =
    Maybe.map
        (\torrent ->
            ( hash
            , lazyRow humanise tableConfig selectedTorrentHash torrent
            )
        )
        (Dict.get hash torrentsByHash)


lazyRow : Model.Config.Humanise -> Config -> Maybe String -> Torrent -> Html Msg
lazyRow humanise tableConfig selectedTorrentHash torrent =
    let
        rowIsSelected =
            Maybe.map ((==) torrent.hash) selectedTorrentHash
                |> Maybe.withDefault False
    in
    Html.Lazy.lazy4 row humanise tableConfig rowIsSelected torrent


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
