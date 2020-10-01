module Model.TorrentFilter exposing (..)

import Model.Torrent exposing (Torrent)
import Regex exposing (Regex)


type alias TorrentFilter =
    { name : Maybe Regex
    }


setName : Maybe String -> TorrentFilter -> TorrentFilter
setName new filter =
    {- convert from string to regex -}
    let
        nameRe =
            Maybe.map (\s -> Regex.fromStringWith { caseInsensitive = True, multiline = False } s) new
                |> Maybe.withDefault Nothing
    in
    { filter | name = nameRe }


torrentMatches : TorrentFilter -> Torrent -> Bool
torrentMatches filter torrent =
    {- return true if it matches the given filter -}
    case filter.name of
        Just s ->
            Regex.contains s torrent.name

        Nothing ->
            True
