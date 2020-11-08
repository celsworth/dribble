module Update.ProcessTorrents exposing (update)

import Dict
import Model exposing (..)
import Model.Sort.Torrent
import Model.Torrent exposing (Torrent)
import Model.TorrentGroups


update : List Torrent -> Model -> ( Model, Cmd Msg )
update torrents model =
    let
        byHash =
            torrentsByHash model torrents

        newGroups =
            Model.TorrentGroups.groups model.torrentGroups (Dict.values byHash)
    in
    model
        |> setSortedTorrents (sortedTorrents byHash model.config.sortBy)
        |> setTorrentsByHash byHash
        |> setTorrentGroups newGroups
        |> noCmd


sortedTorrents : Model.Torrent.TorrentsByHash -> Model.Torrent.Sort -> List String
sortedTorrents byHash sortBy =
    Model.Sort.Torrent.sort sortBy (Dict.values byHash)


torrentsByHash : Model -> List Torrent -> Model.Torrent.TorrentsByHash
torrentsByHash model torrentList =
    let
        newDict =
            Dict.fromList <| List.map (\t -> ( t.hash, t )) torrentList
    in
    Dict.union newDict model.torrentsByHash
