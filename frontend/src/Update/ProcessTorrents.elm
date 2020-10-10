module Update.ProcessTorrents exposing (update)

import Dict exposing (Dict)
import Model exposing (..)
import Model.Attribute
import Model.Sort.Torrent
import Model.Torrent exposing (Torrent)


update : List Torrent -> Model -> ( Model, Cmd Msg )
update torrents model =
    let
        byHash =
            torrentsByHash model torrents

        (Model.Attribute.SortBy sortByAttribute sortByDir) =
            model.config.sortBy

        attribute =
            case sortByAttribute of
                Model.Attribute.TorrentAttribute torrentAttr ->
                    torrentAttr

        sortedTorrents =
            Model.Sort.Torrent.sort attribute sortByDir (Dict.values byHash)
    in
    model
        |> setSortedTorrents sortedTorrents
        |> setTorrentsByHash byHash
        |> noCmd


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
