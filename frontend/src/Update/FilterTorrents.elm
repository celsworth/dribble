module Update.FilterTorrents exposing (update)

import Dict
import Model exposing (..)
import Model.Torrent exposing (Torrent)
import Model.TorrentFilter as TF
import Model.TorrentGroups


update : Model -> ( Model, Cmd Msg )
update model =
    let
        newFilteredTorrents =
            filteredTorrents model
    in
    model
        |> setFilteredTorrents newFilteredTorrents
        |> noCmd


filteredTorrents : Model -> List String
filteredTorrents model =
    let
        fn =
            \hash ->
                Dict.get hash model.torrentsByHash
                    |> torrentMatches model
    in
    List.filter fn model.sortedTorrents


torrentMatches : Model -> Maybe Torrent -> Bool
torrentMatches model maybeTorrent =
    case maybeTorrent of
        Just torrent ->
            torrentMatchesFilter model torrent
                && torrentMatchesSelectedGroups model torrent

        Nothing ->
            False


torrentMatchesSelectedGroups : Model -> Torrent -> Bool
torrentMatchesSelectedGroups { currentTime, torrentGroups } torrent =
    let
        -- TODO: statusExpr!
        labelExpr =
            TF.OrExpr <| Model.TorrentGroups.selectedExprs torrentGroups.byLabel

        trackerExpr =
            TF.OrExpr <| Model.TorrentGroups.selectedExprs torrentGroups.byTracker

        expr =
            TF.AndExpr [ labelExpr, trackerExpr ]
    in
    TF.torrentMatchesExpr currentTime torrent expr


torrentMatchesFilter : Model -> Torrent -> Bool
torrentMatchesFilter { currentTime, torrentFilter } torrent =
    TF.torrentMatches currentTime torrent torrentFilter
