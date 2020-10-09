module Model.TorrentFilter exposing
    ( Config
    , TorrentFilter
    , decoder
    , default
    , encode
    , filterFromConfig
    , setName
    , torrentMatches
    )

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
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
    {- generated at runtime and used for filtering -}
    { name : NameFilter
    }


type alias Config =
    {- stored in Config and saved to localStorage -}
    { name : String }



-- DEFAULT


default : Config
default =
    { name = ""
    }



-- JSON ENCODER


encode : Config -> E.Value
encode config =
    E.object
        [ ( "name", E.string config.name )
        ]



-- JSON DECODER


decoder : D.Decoder Config
decoder =
    D.succeed Config
        |> optional "name" D.string default.name



-- SETTERS


setName : String -> Config -> Config
setName new config =
    { config | name = new }


filterFromConfig : Config -> TorrentFilter
filterFromConfig config =
    { name = parseName config.name }



-- FILTERS


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



-- PARSER


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
