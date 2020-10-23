module Model.GroupLists exposing (..)

import Dict exposing (Dict)
import Model.Torrent exposing (Torrent)
import Model.Tracker


type alias Group =
    Dict String Int


type alias GroupLists =
    { byLabel : Group
    , byTracker : Group
    , byStatus : Group
    }


empty : GroupLists
empty =
    { byLabel = Dict.empty
    , byTracker = Dict.empty
    , byStatus = Dict.empty
    }


groups : List Torrent -> GroupLists
groups torrents =
    { byLabel = createByLabel torrents
    , byTracker = createByTracker torrents
    , byStatus = Dict.empty
    }


createByLabel : List Torrent -> Group
createByLabel torrents =
    List.foldr
        (\torrent carry -> incrementKey torrent.label carry)
        Dict.empty
        torrents


createByTracker : List Torrent -> Group
createByTracker torrents =
    List.foldr
        (\torrent carry ->
            List.foldr
                (\host carry2 -> incrementKey host carry2)
                carry
                torrent.trackerHosts
        )
        Dict.empty
        torrents


incrementKey : String -> Group -> Group
incrementKey key carry =
    Dict.update
        key
        (\existingCount ->
            Maybe.map (\e -> e + 1) existingCount
                |> Maybe.withDefault 1
                |> Just
        )
        carry
