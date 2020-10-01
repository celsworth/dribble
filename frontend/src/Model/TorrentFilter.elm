module Model.TorrentFilter exposing (..)

import Model.Torrent exposing (Torrent)
import Regex exposing (Regex)


type alias TorrentFilter =
    { name : Maybe Regex
    }


setName : String -> TorrentFilter -> TorrentFilter
setName new filter =
    {- convert from string to regex -}
    let
        nameRe =
            if String.isEmpty new then
                Nothing

            else
                stringToRegex new
    in
    { filter | name = nameRe }


stringToRegex : String -> Maybe Regex
stringToRegex input =
    Regex.fromStringWith { caseInsensitive = True, multiline = False } input


torrentMatches : TorrentFilter -> Torrent -> Bool
torrentMatches filter torrent =
    {- return true if it matches the given filter -}
    case filter.name of
        Just re ->
            Regex.contains re torrent.name

        Nothing ->
            True
