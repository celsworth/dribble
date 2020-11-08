module Update.FilterTorrents exposing (update)

import Dict
import Model exposing (..)
import Model.Torrent exposing (Torrent, TorrentsByHash)
import Model.TorrentFilter exposing (TorrentFilter)
import Time exposing (Posix)


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
                torrentMatches model (Dict.get hash model.torrentsByHash)
    in
    List.filter fn model.sortedTorrents


torrentMatches : Model -> Maybe Torrent -> Bool
torrentMatches { currentTime, torrentFilter } maybeTorrent =
    case maybeTorrent of
        Just torrent ->
            Model.TorrentFilter.torrentMatches currentTime torrent torrentFilter

        Nothing ->
            False
