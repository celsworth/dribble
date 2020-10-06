module Model.TorrentFilter exposing (..)

import Model.Torrent exposing (Torrent)
import Regex exposing (Regex)


type NameFilter
    = Regex Regex
    | Error
    | Unset


type alias TorrentFilter =
    { name : NameFilter
    }


setName : String -> TorrentFilter -> TorrentFilter
setName new filter =
    { filter | name = parseName new }


torrentMatches : TorrentFilter -> Torrent -> Bool
torrentMatches filter torrent =
    {- return true if it matches the given filter -}
    case filter.name of
        Regex re ->
            Regex.contains re torrent.name

        Error ->
            False

        Unset ->
            True


parseName : String -> NameFilter
parseName input =
    if String.isEmpty input then
        Unset

    else
        {- this does a lot.
           * remove left/right whitespace
           * split on spaces
           * make those into (?=.*<foo>)
           * join those together
           * make a Regex; if it fails make an Error
        -}
        String.trim input
            |> String.split " "
            |> List.map (\s -> "(?=.*" ++ s ++ ")")
            |> String.concat
            |> Regex.fromStringWith { caseInsensitive = True, multiline = False }
            |> Maybe.map Regex
            |> Maybe.withDefault Error
