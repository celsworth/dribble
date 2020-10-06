module Model.TorrentFilter exposing (..)

import Model.Torrent exposing (Torrent)
import Parser exposing ((|.), (|=), Parser, Step(..))
import Regex exposing (Regex)


type NameFilter
    = Filters (List NameFilterComponent)
    | Unset


type NameFilterComponent
    = Regex Regex
    | ExactMatch String
    | Error


type alias TorrentFilter =
    { name : NameFilter
    }


setName : String -> TorrentFilter -> TorrentFilter
setName new filter =
    { filter | name = parseName new }


torrentMatches : Torrent -> TorrentFilter -> Bool
torrentMatches torrent filter =
    case filter.name of
        Filters filters ->
            List.all (torrentMatches2 torrent) filters

        Unset ->
            True


torrentMatches2 : Torrent -> NameFilterComponent -> Bool
torrentMatches2 torrent filter =
    case filter of
        Regex re ->
            Regex.contains re torrent.name

        ExactMatch str ->
            String.contains (String.toLower str) (String.toLower torrent.name)

        Error ->
            False


parseName : String -> NameFilter
parseName input =
    case Parser.run parseNameFilter input of
        Ok nameFilter ->
            nameFilter

        Err _ ->
            Unset


parseNameFilter : Parser NameFilter
parseNameFilter =
    Parser.map Filters <|
        Parser.loop [] parseNameFilterComponents


parseNameFilterComponents : List NameFilterComponent -> Parser (Step (List NameFilterComponent) (List NameFilterComponent))
parseNameFilterComponents filters =
    Parser.oneOf
        [ Parser.succeed ()
            |. Parser.end
            |> Parser.map (\_ -> Parser.Done filters)
        , Parser.succeed (\filter -> Parser.Loop (filter :: filters))
            |= parseNameFilterComponent
            |. Parser.spaces
        ]


parseNameFilterComponent : Parser NameFilterComponent
parseNameFilterComponent =
    Parser.oneOf [ parseExactMatch, parseRegex ]


parseExactMatch : Parser NameFilterComponent
parseExactMatch =
    Parser.succeed ExactMatch
        |. Parser.symbol "\""
        |= (Parser.getChompedString <|
                Parser.succeed ()
                    |. Parser.chompUntil "\""
           )
        |. Parser.symbol "\""


parseRegex : Parser NameFilterComponent
parseRegex =
    Parser.succeed convertStringToRegex
        |= (Parser.getChompedString <|
                Parser.succeed ()
                    |. Parser.chompUntilEndOr " "
           )


convertStringToRegex : String -> NameFilterComponent
convertStringToRegex str =
    str
        |> Regex.fromStringWith { caseInsensitive = True, multiline = False }
        |> Maybe.map Regex
        |> Maybe.withDefault Error
