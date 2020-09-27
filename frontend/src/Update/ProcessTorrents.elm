module Update.ProcessTorrents exposing (update)

import Dict exposing (Dict)
import Model exposing (..)
import Model.Torrent exposing (Torrent)


update : List Torrent -> Model -> Model
update torrents model =
    let
        byHash =
            torrentsByHash model torrents

        sortedTorrents =
            Model.Torrent.sort model.config.sortBy
                (Dict.values byHash)
    in
    { model | sortedTorrents = sortedTorrents, torrentsByHash = byHash }


torrentsByHash : Model -> List Torrent -> Dict String Torrent
torrentsByHash model torrentList =
    let
        newDict =
            Dict.fromList <| List.map (\t -> ( t.hash, t )) torrentList
    in
    if Dict.isEmpty model.torrentsByHash then
        newDict

    else
        Dict.union newDict model.torrentsByHash
