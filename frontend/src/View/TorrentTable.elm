module View.TorrentTable exposing (view)

{- this is for rendering Torrent Tables as they're slightly special.

   it calls out to View.Table for some common functionality but Torrent Tables
   are special enough that they need some of their own functionality

   * keyed rows
   * filtering
   * separate sorted list/hash to avoid invalidating lazy cache
-}

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed as Keyed
import Html.Lazy
import List
import Model exposing (..)
import Model.Attribute
import Model.Config
import Model.Table
import Model.Torrent exposing (Torrent, TorrentsByHash)
import Model.TorrentFilter exposing (TorrentFilter)
import Round
import Utils.Filesize
import View.DragBar
import View.Table
import View.Torrent
import View.Utils.LocalTimeNode


view : Model -> Html Msg
view model =
    if List.isEmpty model.sortedTorrents then
        section [ class "torrents loading" ]
            [ i [ class "fas fa-spinner fa-pulse" ] [] ]

    else
        section [ class "torrents" ]
            [ table []
                [ Html.Lazy.lazy View.DragBar.view model.resizeOp
                , Html.Lazy.lazy2 View.Table.header model.config model.config.torrentTable
                , Html.Lazy.lazy5 body
                    model.config.humanise
                    model.config.torrentTable
                    model.torrentFilter
                    model.torrentsByHash
                    model.sortedTorrents
                ]
            ]


body : Model.Config.Humanise -> Model.Table.Config -> TorrentFilter -> TorrentsByHash -> List String -> Html Msg
body humanise tableConfig torrentFilter torrentsByHash sortedTorrents =
    Keyed.node "tbody" [] <|
        List.filterMap identity
            (List.map
                (keyedRow humanise tableConfig torrentFilter torrentsByHash)
                sortedTorrents
            )


keyedRow : Model.Config.Humanise -> Model.Table.Config -> TorrentFilter -> TorrentsByHash -> String -> Maybe ( String, Html Msg )
keyedRow humanise tableConfig torrentFilter torrentsByHash hash =
    Maybe.map
        (\torrent -> ( hash, lazyRow humanise tableConfig (Just torrentFilter) torrent ))
        (Dict.get hash torrentsByHash)


lazyRow : Model.Config.Humanise -> Model.Table.Config -> Maybe TorrentFilter -> Torrent -> Html Msg
lazyRow humanise tableConfig torrentFilter torrent =
    let
        matches =
            Maybe.map (Model.TorrentFilter.torrentMatches torrent) torrentFilter
                |> Maybe.withDefault True
    in
    if matches then
        -- pass in as little as possible so lazy works as well as possible
        Html.Lazy.lazy3 row humanise tableConfig torrent

    else
        text ""


row : Model.Config.Humanise -> Model.Table.Config -> Torrent -> Html Msg
row humanise tableConfig torrent =
    let
        {-
           _ =
               Debug.log "rendering:" torrent
        -}
        visibleColumns =
            List.filter .visible tableConfig.columns
    in
    tr [] (List.map (cell tableConfig humanise torrent) visibleColumns)


cell : Model.Table.Config -> Model.Config.Humanise -> Torrent -> Model.Table.Column -> Html Msg
cell tableConfig humanise torrent column =
    td []
        [ div (View.Table.cellAttributes tableConfig column)
            [ cellContent humanise torrent column ]
        ]


cellContent : Model.Config.Humanise -> Torrent -> Model.Table.Column -> Html Msg
cellContent humanise torrent column =
    case column.attribute of
        Model.Attribute.TorrentAttribute Model.Torrent.Status ->
            torrentStatusCell torrent

        Model.Attribute.TorrentAttribute Model.Torrent.DonePercent ->
            donePercentCell torrent

        Model.Attribute.TorrentAttribute torrentAttribute ->
            View.Torrent.attributeAccessor humanise torrent torrentAttribute

        _ ->
            Debug.todo "not reachable, can we remove this?"


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
