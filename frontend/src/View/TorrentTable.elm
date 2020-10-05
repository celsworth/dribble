module View.TorrentTable exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse
import Html.Keyed as Keyed
import Html.Lazy
import List
import Model exposing (..)
import Model.Config exposing (Config)
import Model.Table
import Model.Torrent exposing (Torrent)
import Model.TorrentFilter exposing (TorrentFilter)
import Round
import View.DragBar
import View.Torrent


view : Model -> Html Msg
view model =
    if List.isEmpty model.sortedTorrents then
        section [ class "torrents loading" ]
            [ i [ class "fas fa-spinner fa-pulse" ] [] ]

    else
        section [ class "torrents" ]
            [ table []
                [ Html.Lazy.lazy View.DragBar.view model.resizeOp
                , Html.Lazy.lazy header model.config
                , Html.Lazy.lazy5 body
                    model.config.humanise
                    model.config.torrentTable
                    model.torrentFilter
                    model.torrentsByHash
                    model.sortedTorrents
                ]
            ]


header : Config -> Html Msg
header config =
    let
        visibleOrder =
            List.filter .visible config.torrentTable.columns
    in
    thead []
        [ tr []
            (List.map (headerCell config) visibleOrder)
        ]


headerCell : Config -> Model.Table.Column -> Html Msg
headerCell config column =
    let
        (Model.Table.TorrentAttribute attribute) =
            column.attribute

        attrString =
            View.Torrent.attributeToTableHeaderString
                attribute

        maybeResizeDiv =
            case config.torrentTable.layout of
                Model.Table.Fixed ->
                    Just <| div (headerCellResizeHandleAttributes attribute) []

                Model.Table.Fluid ->
                    Nothing
    in
    th (headerCellAttributes config.sortBy attribute)
        (List.filterMap identity
            [ Just <|
                div (headerCellContentDivAttributes config.torrentTable attribute)
                    [ div [ class "content" ] [ text attrString ] ]
            , maybeResizeDiv
            ]
        )


headerCellAttributes : Model.Torrent.Sort -> Model.Torrent.Attribute -> List (Attribute Msg)
headerCellAttributes sortBy attribute =
    List.filterMap identity
        [ headerCellIdAttribute attribute
        , cellTextAlign attribute
        , headerCellSortClass sortBy attribute
        ]


headerCellIdAttribute : Model.Torrent.Attribute -> Maybe (Attribute Msg)
headerCellIdAttribute attribute =
    Just <| id (View.Torrent.attributeToTableHeaderId attribute)


headerCellContentDivAttributes : Model.Table.Config -> Model.Torrent.Attribute -> List (Attribute Msg)
headerCellContentDivAttributes tableConfig attribute =
    let
        maybeWidthAttr =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    thWidthAttribute tableConfig attribute

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity
        [ maybeWidthAttr
        , Just <| onClick (SetSortBy attribute)
        ]


headerCellResizeHandleAttributes : Model.Torrent.Attribute -> List (Attribute Msg)
headerCellResizeHandleAttributes attribute =
    let
        {- this mess converts (x, y) to { x: x, y: y } -}
        reconstructClientPos =
            \event ->
                let
                    ( x, y ) =
                        event.clientPos
                in
                { x = x, y = y }
    in
    [ class "resize-handle"
    , Html.Events.Extra.Mouse.onDown
        (\e ->
            MouseDown
                (Model.Table.TorrentAttribute attribute)
                (reconstructClientPos e)
                e.button
                e.keys
        )
    ]


headerCellSortClass : Model.Torrent.Sort -> Model.Torrent.Attribute -> Maybe (Attribute Msg)
headerCellSortClass sortBy attribute =
    let
        (Model.Torrent.SortBy currentSortAttribute currentSortDirection) =
            sortBy
    in
    if currentSortAttribute == attribute then
        case currentSortDirection of
            Model.Torrent.Asc ->
                Just <| class "sorted ascending"

            Model.Torrent.Desc ->
                Just <| class "sorted descending"

    else
        Nothing


body : Model.Config.Humanise -> Model.Table.Config -> TorrentFilter -> TorrentsByHash -> List String -> Html Msg
body humanise tableConfig torrentFilter torrentsByHash sortedTorrents =
    Keyed.node "tbody" [] <|
        List.filterMap identity
            (List.map
                (keyedRow humanise
                    tableConfig
                    torrentFilter
                    torrentsByHash
                )
                sortedTorrents
            )


keyedRow : Model.Config.Humanise -> Model.Table.Config -> TorrentFilter -> TorrentsByHash -> String -> Maybe ( String, Html Msg )
keyedRow humanise tableConfig torrentFilter torrentsByHash hash =
    Maybe.map
        (\torrent -> ( hash, lazyRow humanise tableConfig torrentFilter torrent ))
        (Dict.get hash torrentsByHash)


lazyRow : Model.Config.Humanise -> Model.Table.Config -> TorrentFilter -> Torrent -> Html Msg
lazyRow humanise tableConfig torrentFilter torrent =
    if Model.TorrentFilter.torrentMatches torrentFilter torrent then
        -- pass in as little as possible so lazy works as well as possible
        Html.Lazy.lazy3 row humanise tableConfig torrent

    else
        text ""


row : Model.Config.Humanise -> Model.Table.Config -> Torrent -> Html Msg
row humanise tableConfig torrent =
    let
        {- _ =
           Debug.log "rendering:" torrent
        -}
        visibleOrder =
            List.filter .visible tableConfig.columns
    in
    tr [] (List.map (cell humanise tableConfig torrent) visibleOrder)


cell : Model.Config.Humanise -> Model.Table.Config -> Torrent -> Model.Table.Column -> Html Msg
cell humanise tableConfig torrent column =
    let
        (Model.Table.TorrentAttribute attribute) =
            column.attribute
    in
    td []
        [ div (cellAttributes tableConfig attribute)
            [ cellContent humanise torrent attribute
            ]
        ]


cellAttributes : Model.Table.Config -> Model.Torrent.Attribute -> List (Attribute Msg)
cellAttributes tableConfig attribute =
    let
        maybeWidthAttr =
            case tableConfig.layout of
                Model.Table.Fixed ->
                    tdWidthAttribute tableConfig attribute

                Model.Table.Fluid ->
                    Nothing
    in
    List.filterMap identity
        [ maybeWidthAttr
        , cellTextAlign attribute
        ]


cellTextAlign : Model.Torrent.Attribute -> Maybe (Attribute Msg)
cellTextAlign attribute =
    Maybe.map class (View.Torrent.textAlignment attribute)


cellContent : Model.Config.Humanise -> Torrent -> Model.Torrent.Attribute -> Html Msg
cellContent humanise torrent attribute =
    case attribute of
        Model.Torrent.Status ->
            torrentStatusCell torrent

        Model.Torrent.DonePercent ->
            donePercentCell torrent

        _ ->
            View.Torrent.attributeAccessor
                humanise
                torrent
                attribute


torrentStatusCell : Torrent -> Html Msg
torrentStatusCell torrent =
    case torrent.status of
        Model.Torrent.Seeding ->
            torrentStatusIcon "seeding" "fa-arrow-up"

        Model.Torrent.Errored ->
            torrentStatusIcon "errored" "fa-times"

        Model.Torrent.Downloading ->
            torrentStatusIcon "downloading" "fa-arrow-down"

        Model.Torrent.Paused ->
            torrentStatusIcon "paused" "fa-pause"

        Model.Torrent.Stopped ->
            torrentStatusIcon "stopped" ""

        Model.Torrent.Hashing ->
            torrentStatusIcon "hashing" "fa-sync"


torrentStatusIcon : String -> String -> Html Msg
torrentStatusIcon kls icon =
    span [ class ("torrent-status " ++ kls ++ " fa-stack") ]
        [ i [ class "fas fa-square fa-stack-2x" ] []
        , i [ class ("fas " ++ icon ++ " fa-inverse fa-stack-1x") ] []
        ]


donePercentCell : Torrent -> Html Msg
donePercentCell torrent =
    let
        dp =
            if torrent.donePercent == 100 then
                0

            else
                1
    in
    div [ class "progress-container" ]
        [ progress
            [ Html.Attributes.max "100"
            , Html.Attributes.value <| Round.round 0 torrent.donePercent
            ]
            []
        , span []
            [ text (Round.round dp torrent.donePercent ++ "%") ]
        ]



{-
   WIDTH HELPERS

   this complication is because the width stored in columnWidths
   includes padding and borders. To set the proper size for the
   internal div, we need to subtract some:

   For th columns, that amounts to 10px (2*4px padding, 2*1px border)

   For td, there are no borders, so its just 2*4px padding to remove
-}


thWidthAttribute : Model.Table.Config -> Model.Torrent.Attribute -> Maybe (Attribute Msg)
thWidthAttribute tableConfig attribute =
    widthAttribute tableConfig attribute 10


tdWidthAttribute : Model.Table.Config -> Model.Torrent.Attribute -> Maybe (Attribute Msg)
tdWidthAttribute tableConfig attribute =
    widthAttribute tableConfig attribute 8


widthAttribute : Model.Table.Config -> Model.Torrent.Attribute -> Float -> Maybe (Attribute Msg)
widthAttribute tableConfig attribute subtract =
    let
        tableColumn =
            Model.Table.getColumn
                tableConfig
                (Model.Table.TorrentAttribute attribute)
    in
    if tableColumn.auto then
        Nothing

    else
        Just <| style "width" (String.fromFloat (tableColumn.width - subtract) ++ "px")
