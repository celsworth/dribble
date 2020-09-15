module View.TorrentTable exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2)
import Model exposing (..)
import Torrent


view : Model -> Html msg
view model =
    table []
        (List.concat
            [ [ torrentTableHeader ]
            , [ torrentTableBody model ]
            ]
        )


torrentTableHeader : Html msg
torrentTableHeader =
    thead []
        [ tr []
            [ th [] [ text "Name" ]
            , th [] [ text "Size" ]
            ]
        ]


torrentTableBody : Model -> Html msg
torrentTableBody model =
    Keyed.node
        "tbody"
        []
        (List.map (keyedTorrentTableRow model) <| sortedTorrents model)


torrentTableBody2 : Model -> Html msg
torrentTableBody2 model =
    let
        visible =
            model.config.visibleTorrentAttributes
    in
    p [] []


sortedTorrents : Model -> List Torrent
sortedTorrents model =
    List.sortWith (sortComparator <| model.config.sortBy) model.torrents


sortComparator : Sort -> Torrent -> Torrent -> Order
sortComparator sortBy a b =
    case sortBy of
        SortBy Name direction ->
            maybeReverse direction <| nameCmp a b

        SortBy Size direction ->
            maybeReverse direction <| sizeCmp a b


nameCmp : Torrent -> Torrent -> Order
nameCmp a b =
    if a.name == b.name then
        EQ

    else if a.name > b.name then
        GT

    else
        LT


sizeCmp : Torrent -> Torrent -> Order
sizeCmp a b =
    if a.size == b.size then
        EQ

    else if a.size > b.size then
        GT

    else
        LT


maybeReverse : SortDirection -> Order -> Order
maybeReverse direction order =
    case direction of
        Asc ->
            order

        Desc ->
            case order of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT


keyedTorrentTableRow : Model -> Torrent -> ( String, Html msg )
keyedTorrentTableRow model torrent =
    ( torrent.hash, lazy2 torrentTableRow model torrent )


torrentTableRow : Model -> Torrent -> Html msg
torrentTableRow model torrent =
    let
        x =
            Debug.log "rendering:" torrent

        cellMethod =
            torrentTableCell torrent
    in
    -- TODO: this should use torrentAttributeOrder and filter by visible?
    tr
        []
        (List.map cellMethod model.config.visibleTorrentAttributes)


torrentTableCell : Torrent -> TorrentAttribute -> Html msg
torrentTableCell torrent attribute =
    let
        content =
            Torrent.torrentAttributeAccessor torrent attribute
    in
    td []
        [ text content
        ]
