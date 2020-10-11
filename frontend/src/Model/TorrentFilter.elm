module Model.TorrentFilter exposing
    ( Config
    , TorrentFilter
    , decoder
    , default
    , encode
    , filterFromConfig
    , setFilter
    , torrentMatches
    )

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional)
import Json.Encode as E
import Model.Torrent exposing (Torrent)
import Parser as P exposing ((|.), (|=), Parser, Step(..), oneOf, symbol)
import Regex exposing (Regex)


type Filter
    = Filters (List FilterComponent)
    | Unset


type StringOp
    = EqStr CaseSensititivy
    | NotEqStr CaseSensititivy
    | Contains CaseSensititivy
    | NotContains CaseSensititivy
    | Matches (Maybe Regex)
    | NotMatches (Maybe Regex)


type CaseSensititivy
    = CaseSensitive String
    | CaseInsensitive String


type NumberOp
    = EqNum
    | NotEqNum
    | GT
    | GTE
    | LT
    | LTE


type SizeSuffix
    = KB
    | MB
    | GB
    | TB
    | KiB
    | MiB
    | GiB
    | TiB
    | Nothing


type FilterComponent
    = Name StringOp
    | Label StringOp
    | Size NumberOp Int SizeSuffix
    | Done NumberOp Float
    | Peers NumberOp Int
    | Ratio NumberOp Float


type alias TorrentFilter =
    {- generated at runtime and used for filtering -}
    { filter : Result (List P.DeadEnd) Filter
    }


type alias Config =
    {- stored in Config and saved to localStorage -}
    { filter : String }



-- DEFAULT


default : Config
default =
    { filter = ""
    }



-- JSON ENCODER


encode : Config -> E.Value
encode config =
    E.object
        [ ( "filter", E.string config.filter )
        ]



-- JSON DECODER


decoder : D.Decoder Config
decoder =
    D.succeed Config
        |> optional "filter" D.string default.filter



-- SETTERS


setFilter : String -> Config -> Config
setFilter new config =
    { config | filter = new }


filterFromConfig : Config -> TorrentFilter
filterFromConfig config =
    { filter = parse config.filter }



-- FILTERS


torrentMatches : Torrent -> TorrentFilter -> Bool
torrentMatches torrent filter =
    case filter.filter of
        Ok (Filters filters) ->
            List.all (torrentMatchesComponent torrent) filters

        Ok Unset ->
            True

        Err _ ->
            False


torrentMatchesComponent : Torrent -> FilterComponent -> Bool
torrentMatchesComponent torrent filter =
    case filter of
        Name op ->
            stringMatcher torrent .name op

        Label op ->
            stringMatcher torrent .label op

        Size op num suffix ->
            sizeSuffixMatcher torrent .size op num suffix

        Peers op num ->
            numberMatcher torrent .peersTotal op num

        Done op num ->
            numberMatcher torrent .donePercent op num

        Ratio op num ->
            -- slightly special
            numberMatcher torrent .ratio op num


sizeSuffixMatcher : Torrent -> (Torrent -> Int) -> NumberOp -> Int -> SizeSuffix -> Bool
sizeSuffixMatcher torrent meth op num suffix =
    let
        multi =
            case suffix of
                KB ->
                    1000

                MB ->
                    1000 ^ 2

                GB ->
                    1000 ^ 3

                TB ->
                    1000 ^ 4

                KiB ->
                    1024

                MiB ->
                    1024 ^ 2

                GiB ->
                    1024 ^ 3

                TiB ->
                    1024 ^ 4

                Nothing ->
                    1
    in
    numberMatcher torrent meth op (num * multi)


stringMatcher : Torrent -> (Torrent -> String) -> StringOp -> Bool
stringMatcher torrent meth op =
    case op of
        EqStr cs ->
            csEq cs (meth torrent)

        NotEqStr cs ->
            not (csEq cs (meth torrent))

        Contains cs ->
            csContains cs (meth torrent)

        NotContains cs ->
            not (csContains cs (meth torrent))

        Matches re ->
            reMatch re (meth torrent)

        NotMatches re ->
            not <| reMatch re (meth torrent)


csEq : CaseSensititivy -> String -> Bool
csEq cs str =
    case cs of
        CaseSensitive term ->
            term == str

        CaseInsensitive term ->
            -- no need for toLower on term, we already checked its all lowercase
            term == String.toLower str


csContains : CaseSensititivy -> String -> Bool
csContains cs str =
    case cs of
        CaseSensitive term ->
            String.contains term str

        CaseInsensitive term ->
            -- no need for toLower on term, we already checked its all lowercase
            String.contains term (String.toLower str)


reMatch : Maybe Regex -> String -> Bool
reMatch re str =
    case re of
        Just x ->
            Regex.contains x str

        _ ->
            False


numberMatcher : Torrent -> (Torrent -> number) -> NumberOp -> number -> Bool
numberMatcher torrent meth op num =
    case op of
        GT ->
            meth torrent > num

        GTE ->
            meth torrent >= num

        LT ->
            meth torrent < num

        LTE ->
            meth torrent <= num

        EqNum ->
            meth torrent == num

        NotEqNum ->
            meth torrent /= num



-- PARSER


parse : String -> Result (List P.DeadEnd) Filter
parse input =
    P.run parseFilter input


parseFilter : Parser Filter
parseFilter =
    P.map Filters <|
        P.loop [] parseFilterComponents


parseFilterComponents : List FilterComponent -> Parser (Step (List FilterComponent) (List FilterComponent))
parseFilterComponents filters =
    oneOf
        [ P.succeed ()
            |. P.end
            |> P.map (\_ -> P.Done filters)
        , P.succeed (\filter -> P.Loop (filter :: filters))
            |= parseFilterComponent
            |. P.spaces
        ]


parseFilterComponent : Parser FilterComponent
parseFilterComponent =
    oneOf [ parseExactMatch, parseOp, parseShortcutRegex ]


parseOp : Parser FilterComponent
parseOp =
    oneOf [ parseStringField, parseSizeField, parseIntField, parseFloatOp ]


parseStringField : Parser FilterComponent
parseStringField =
    oneOf
        [ P.map (\_ -> Name) (P.keyword "name")
        , P.map (\_ -> Label) (P.keyword "label")
        ]
        |. P.spaces
        |= oneOf
            [ P.backtrackable parseCsExactStringOp
            , parseCsStringOp
            , parseReStringOp
            ]


parseCsExactStringOp : Parser StringOp
parseCsExactStringOp =
    oneOf
        [ P.map (\_ -> Contains) (symbol "=")
        , P.map (\_ -> NotContains) (symbol "!=")
        , P.map (\_ -> EqStr) (symbol "==")
        , P.map (\_ -> NotEqStr) (symbol "!==")
        ]
        |. P.spaces
        |. symbol "\""
        |= P.map toCs (P.getChompedString <| P.chompUntil "\"")
        |. symbol "\""


parseCsStringOp : Parser StringOp
parseCsStringOp =
    oneOf
        [ P.map (\_ -> Contains) (symbol "=")
        , P.map (\_ -> NotContains) (symbol "!=")
        , P.map (\_ -> EqStr) (symbol "==")
        , P.map (\_ -> NotEqStr) (symbol "!==")
        ]
        |. P.spaces
        |= P.map toCs (P.getChompedString <| P.chompUntilEndOr " ")


parseReStringOp : Parser StringOp
parseReStringOp =
    oneOf
        [ P.map (\_ -> Matches) (symbol "~")
        , P.map (\_ -> NotMatches) (symbol "!~")
        ]
        |. P.spaces
        |= P.map toRe (P.getChompedString <| P.chompUntilEndOr " ")


parseIntField : Parser FilterComponent
parseIntField =
    oneOf
        [ P.map (\_ -> Peers) (P.keyword "peers")
        ]
        |. P.spaces
        |= numberOpParser
        |. P.spaces
        |= P.int


parseFloatOp : Parser FilterComponent
parseFloatOp =
    oneOf
        [ P.map (\_ -> Ratio) (P.keyword "ratio")
        , P.map (\_ -> Done) (P.keyword "done")
        ]
        |. P.spaces
        |= numberOpParser
        |. P.spaces
        |= P.float


parseSizeField : Parser FilterComponent
parseSizeField =
    oneOf
        [ P.map (\_ -> Size) (P.keyword "size")
        ]
        |. P.spaces
        |= numberOpParser
        |. P.spaces
        |= P.int
        |= sizeSuffixParser


numberOpParser : Parser NumberOp
numberOpParser =
    oneOf
        [ P.map (\_ -> EqNum) (symbol "=")
        , P.map (\_ -> NotEqNum) (symbol "!=")
        , P.map (\_ -> GT) (symbol ">")
        , P.map (\_ -> GTE) (symbol ">=")
        , P.map (\_ -> LT) (symbol "<")
        , P.map (\_ -> LTE) (symbol "<=")
        ]


sizeSuffixParser : Parser SizeSuffix
sizeSuffixParser =
    oneOf
        [ P.map (\_ -> KiB) <| oneOf [ symbol "Ki", symbol "ki" ]
        , P.map (\_ -> MiB) <| oneOf [ symbol "Mi", symbol "mi" ]
        , P.map (\_ -> GiB) <| oneOf [ symbol "Gi", symbol "gi" ]
        , P.map (\_ -> TiB) <| oneOf [ symbol "Ti", symbol "ti" ]
        , P.map (\_ -> KB) <| oneOf [ symbol "K", symbol "k" ]
        , P.map (\_ -> MB) <| oneOf [ symbol "M", symbol "m" ]
        , P.map (\_ -> GB) <| oneOf [ symbol "G", symbol "g" ]
        , P.map (\_ -> TB) <| oneOf [ symbol "T", symbol "t" ]
        , P.succeed Nothing
        ]
        |. oneOf
            [ P.map (\_ -> Nothing) <| oneOf [ symbol "B", symbol "b" ]
            , P.succeed Nothing
            ]


parseExactMatch : Parser FilterComponent
parseExactMatch =
    P.map (Name << Contains << toCs) <|
        P.succeed identity
            |. symbol "\""
            |= (P.getChompedString <| P.chompUntil "\"")
            |. symbol "\""


parseShortcutRegex : Parser FilterComponent
parseShortcutRegex =
    P.map (Name << Matches << toRe) <|
        P.succeed identity
            |= (P.getChompedString <| P.chompUntilEndOr " ")


toCs : String -> CaseSensititivy
toCs str =
    -- this enables smart case search.
    -- If the term has any uppercase, store it under CaseSensitive.
    -- later we will not do toLower on the target string to make this work.
    if String.any Char.isUpper str then
        CaseSensitive str

    else
        CaseInsensitive str


toRe : String -> Maybe Regex
toRe str =
    let
        caseInsensitive =
            not (String.any Char.isUpper str)
    in
    str |> Regex.fromStringWith { caseInsensitive = caseInsensitive, multiline = False }
