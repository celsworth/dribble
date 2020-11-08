module Model.TorrentFilter exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional)
import Json.Encode as E
import Model.Torrent exposing (Torrent)
import Parser as P
    exposing
        ( (|.)
        , (|=)
        , Parser
        , Step(..)
        , keyword
        , oneOf
        , symbol
        )
import Regex exposing (Regex)
import Time
import Time.Extra


type CaseSensititivy
    = CaseSensitive String
    | CaseInsensitive String


type StatusOp
    = EqStatus
    | NotEqStatus


type StringOp
    = EqStr CaseSensititivy
    | NotEqStr CaseSensititivy
    | Contains CaseSensititivy
    | NotContains CaseSensititivy
    | Matches Regex
    | NotMatches Regex


type NumberOp
    = EqNum
    | NotEqNum
    | GT
    | GTE
    | LT
    | LTE


type TimeComparison
    = Absolute Int
    | Relative Int


type RelativeTimeSuffix
    = Second
    | Hour
    | Minute
    | Day
    | Week
    | Year


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


type Operator
    = And
    | Or


type Expr
    = AndExpr Expr Expr
    | OrExpr Expr Expr
    | Unset
    | Status StatusOp Model.Torrent.Status
    | Name StringOp
    | Label StringOp
    | Tracker StringOp
    | Size NumberOp Int SizeSuffix
    | Downloaded NumberOp Int SizeSuffix
    | Uploaded NumberOp Int SizeSuffix
    | DownRate NumberOp Int SizeSuffix
    | UpRate NumberOp Int SizeSuffix
    | Created NumberOp TimeComparison
    | Started NumberOp TimeComparison
    | Finished NumberOp TimeComparison
    | Done NumberOp Float
    | SeedersConnected NumberOp Int
    | SeedersTotal NumberOp Int
    | PeersConnected NumberOp Int
    | PeersTotal NumberOp Int
    | Ratio NumberOp Float


type alias TorrentFilter =
    {- generated at runtime and used for filtering -}
    { filter : Result (List P.DeadEnd) Expr
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


torrentMatches : Time.Posix -> Torrent -> TorrentFilter -> Bool
torrentMatches currentTime torrent filter =
    case filter.filter of
        Ok e ->
            torrentMatchesComponent currentTime torrent e

        Err _ ->
            False


torrentMatchesComponent : Time.Posix -> Torrent -> Expr -> Bool
torrentMatchesComponent currentTime torrent filter =
    case filter of
        Unset ->
            True

        AndExpr e1 e2 ->
            torrentMatchesComponent currentTime torrent e1
                && torrentMatchesComponent currentTime torrent e2

        OrExpr e1 e2 ->
            torrentMatchesComponent currentTime torrent e1
                || torrentMatchesComponent currentTime torrent e2

        Status op s ->
            case op of
                EqStatus ->
                    torrent.status == s

                NotEqStatus ->
                    torrent.status /= s

        Name op ->
            stringMatcher torrent.name op

        Label op ->
            stringMatcher torrent.label op

        Tracker op ->
            List.any (\h -> stringMatcher h op) torrent.trackerHosts

        Size op num suffix ->
            sizeSuffixMatcher torrent.size op num suffix

        Downloaded op num suffix ->
            sizeSuffixMatcher torrent.downloadedBytes op num suffix

        Uploaded op num suffix ->
            sizeSuffixMatcher torrent.uploadedBytes op num suffix

        DownRate op num suffix ->
            sizeSuffixMatcher torrent.downloadRate op num suffix

        UpRate op num suffix ->
            sizeSuffixMatcher torrent.uploadRate op num suffix

        Created op tc ->
            timeMatcher currentTime torrent.creationTime op tc

        Started op tc ->
            timeMatcher currentTime torrent.startedTime op tc

        Finished op tc ->
            timeMatcher currentTime torrent.finishedTime op tc

        SeedersConnected op num ->
            numberMatcher torrent.seedersConnected op num

        SeedersTotal op num ->
            numberMatcher torrent.seedersTotal op num

        PeersConnected op num ->
            numberMatcher torrent.peersConnected op num

        PeersTotal op num ->
            numberMatcher torrent.peersTotal op num

        Done op num ->
            numberMatcher torrent.donePercent op num

        Ratio op num ->
            numberMatcher torrent.ratio op num


sizeSuffixMatcher : Int -> NumberOp -> Int -> SizeSuffix -> Bool
sizeSuffixMatcher cmpNum op num suffix =
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
    numberMatcher cmpNum op (num * multi)


stringMatcher : String -> StringOp -> Bool
stringMatcher str op =
    case op of
        EqStr cs ->
            csEq cs str

        NotEqStr cs ->
            not (csEq cs str)

        Contains cs ->
            csContains cs str

        NotContains cs ->
            not (csContains cs str)

        Matches re ->
            reMatch re str

        NotMatches re ->
            not <| reMatch re str


timeMatcher : Time.Posix -> Int -> NumberOp -> TimeComparison -> Bool
timeMatcher currentTime cmpTime op tc =
    case tc of
        Absolute time ->
            numberMatcher cmpTime op time

        Relative age ->
            {- note the negation here. this is because for "started<1w" we
               actually want .startedTime > now-1w
            -}
            not <| numberMatcher cmpTime op (Time.posixToMillis currentTime - age)


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


reMatch : Regex -> String -> Bool
reMatch re str =
    Regex.contains re str


numberMatcher : number -> NumberOp -> number -> Bool
numberMatcher num2 op num =
    case op of
        GT ->
            num2 > num

        GTE ->
            num2 >= num

        LT ->
            num2 < num

        LTE ->
            num2 <= num

        EqNum ->
            num2 == num

        NotEqNum ->
            num2 /= num



-- PARSER


parse : String -> Result (List P.DeadEnd) Expr
parse input =
    P.run expression input


expression : Parser Expr
expression =
    component |> P.andThen (expressionHelp [])



{- currently unused..  this enables precedence by using () around expressions.

   this sort of works, but the () really confuse parseShortcutNameRegex,
   because it wants to match until a space or end, so it captures trailing
   ) .. which then breaks the rest of the parsing.

   we sort of need "chomp until space, or end, or )
   but that doesn't exist..

   component : Parser Expr
   component =
     oneOf
         [ P.map (\_ -> Unset) P.end
         , P.succeed identity
             |. P.symbol "("
             |. P.spaces
             |= P.lazy (\_ -> expression)
             |. P.spaces
             |. P.symbol ")"
         , parseExpr
         ]
-}


component : Parser Expr
component =
    parseExpr


expressionHelp : List ( Expr, Operator ) -> Expr -> Parser Expr
expressionHelp revOps expr =
    oneOf
        [ P.succeed (finalize revOps expr)
            |. P.end
        , P.succeed Tuple.pair
            |. P.spaces
            |= operator
            |. P.spaces
            |= component
            |> P.andThen
                (\( op, newExpr ) -> expressionHelp (( expr, op ) :: revOps) newExpr)
        , P.lazy (\_ -> P.succeed (finalize revOps expr))
        ]


operator : Parser Operator
operator =
    oneOf
        [ P.map (\_ -> Or) <| oneOf [ keyword "OR", keyword "or" ]
        , P.map (\_ -> And) <| oneOf [ keyword "AND", keyword "and", P.spaces ]
        ]


finalize : List ( Expr, Operator ) -> Expr -> Expr
finalize revOps finalExpr =
    case revOps of
        [] ->
            finalExpr

        ( expr, And ) :: otherRevOps ->
            finalize otherRevOps (AndExpr expr finalExpr)

        ( expr, Or ) :: otherRevOps ->
            OrExpr (finalize otherRevOps expr) finalExpr


parseExpr : Parser Expr
parseExpr =
    oneOf
        [ P.map (\_ -> Unset) P.end
        , parseShortcutNameContains
        , parseFieldAlias
        , parseFieldOp
        , parseShortcutNameRegex
        ]


parseFieldAlias : Parser Expr
parseFieldAlias =
    oneOf
        [ P.map
            (\_ -> OrExpr (UpRate GT 0 Nothing) (DownRate GT 0 Nothing))
            (keyword "$active")
        , P.map
            (\_ -> AndExpr (UpRate EqNum 0 Nothing) (DownRate EqNum 0 Nothing))
            (keyword "$idle")
        , P.map (\_ -> stuck) (keyword "$stuck")
        ]


parseFieldOp : Parser Expr
parseFieldOp =
    oneOf
        [ parseStringField
        , parseStatusField
        , parseTimeField
        , parseSizeField
        , parseIntField
        , parseFloatField
        ]


parseStringField : Parser Expr
parseStringField =
    oneOf
        [ P.map (\_ -> Name) (keyword "name")
        , P.map (\_ -> Label) (keyword "label")
        , P.map (\_ -> Tracker) (keyword "tracker")
        ]
        |. P.spaces
        |= oneOf [ parseCsStringOp, parseReStringOp ]


parseCsStringOp : Parser StringOp
parseCsStringOp =
    oneOf
        [ P.map (\_ -> NotEqStr) (symbol "!==")
        , P.map (\_ -> NotContains) (symbol "!=")
        , P.map (\_ -> EqStr) (symbol "==")
        , P.map (\_ -> Contains) (symbol "=")
        ]
        |. P.spaces
        |= oneOf
            [ P.succeed identity
                |. symbol "\""
                |= (P.chompUntilEndOr "\"" |> P.getChompedString |> P.andThen toCs)
                |. symbol "\""
            , P.succeed identity
                |= (P.chompUntilEndOr " " |> P.getChompedString |> P.andThen toCs)
            ]


parseReStringOp : Parser StringOp
parseReStringOp =
    oneOf
        [ P.map (\_ -> Matches) (symbol "~")
        , P.map (\_ -> NotMatches) (symbol "!~")
        ]
        |. P.spaces
        |= (P.chompUntilEndOr " " |> P.getChompedString |> P.andThen toRe)


parseStatusField : Parser Expr
parseStatusField =
    P.succeed (\op status -> Status op status)
        |. keyword "status"
        |. P.spaces
        |= oneOf
            [ P.map (\_ -> NotEqStatus) (symbol "!=")
            , P.map (\_ -> EqStatus) (symbol "=")
            ]
        |. P.spaces
        |= oneOf
            [ P.map (\_ -> Model.Torrent.Seeding) (keyword "seeding")
            , P.map (\_ -> Model.Torrent.Errored)
                (oneOf [ keyword "error", keyword "errored" ])
            , P.map (\_ -> Model.Torrent.Downloading) (keyword "downloading")
            , P.map (\_ -> Model.Torrent.Paused) (keyword "paused")
            , P.map (\_ -> Model.Torrent.Stopped) (keyword "stopped")
            , P.map (\_ -> Model.Torrent.Hashing) (keyword "hashing")
            ]


parseTimeField : Parser Expr
parseTimeField =
    oneOf
        [ P.map (\_ -> Created) (keyword "created")
        , P.map (\_ -> Started) (keyword "started")
        , P.map (\_ -> Finished) (keyword "finished")
        ]
        |. P.spaces
        |= parseNumberOp
        |. P.spaces
        |= oneOf [ P.backtrackable parseAbsoluteTime, parseRelativeTime ]


parseAbsoluteTime : Parser TimeComparison
parseAbsoluteTime =
    -- 2020/01/01 or 2020-01-01 -> TimeComparison Absolute <millis>
    P.succeed (\y m d -> Absolute <| partsToMillis y m d)
        |= P.int
        |. oneOf [ P.symbol "/", P.symbol "-" ]
        -- ignore leading 0s which P.int barfs on
        |. oneOf [ symbol "0", P.succeed () ]
        |= P.int
        |. oneOf [ P.symbol "/", P.symbol "-" ]
        |. oneOf [ symbol "0", P.succeed () ]
        |= P.int


partsToMillis : Int -> Int -> Int -> Int
partsToMillis y m d =
    Time.Extra.partsToPosix Time.utc
        (Time.Extra.Parts y (translateMonthIntToPart m) d 0 0 0 0)
        |> Time.posixToMillis


parseRelativeTime : Parser TimeComparison
parseRelativeTime =
    P.succeed (\i s -> Relative <| translateRelativeTime i s * 1000)
        |= P.int
        |= oneOf
            [ P.map (\_ -> Year) (keyword "y")
            , P.map (\_ -> Week) (keyword "w")
            , P.map (\_ -> Day) (keyword "d")
            , P.map (\_ -> Hour) (keyword "h")
            , P.map (\_ -> Minute) (keyword "m")
            , P.map (\_ -> Second) (oneOf [ keyword "s", P.succeed () ])
            ]


parseIntField : Parser Expr
parseIntField =
    oneOf
        [ P.map (\_ -> SeedersTotal) (keyword "seeders")
        , P.map (\_ -> SeedersConnected) (keyword "seedersc")
        , P.map (\_ -> PeersTotal) (keyword "peers")
        , P.map (\_ -> PeersConnected) (keyword "peersc")
        ]
        |. P.spaces
        |= parseNumberOp
        |. P.spaces
        |= P.int


parseFloatField : Parser Expr
parseFloatField =
    oneOf
        [ P.map (\_ -> Ratio) (keyword "ratio")
        , P.map (\_ -> Done) (keyword "done")
        ]
        |. P.spaces
        |= parseNumberOp
        |. P.spaces
        |= P.float


parseSizeField : Parser Expr
parseSizeField =
    oneOf
        [ P.map (\_ -> Size) (keyword "size")
        , P.map (\_ -> Downloaded) (keyword "downloaded")
        , P.map (\_ -> Uploaded) (keyword "uploaded")
        , P.map (\_ -> DownRate) (keyword "down")
        , P.map (\_ -> UpRate) (keyword "up")
        ]
        |. P.spaces
        |= parseNumberOp
        |. P.spaces
        |= P.int
        |= parseSizeSuffix


parseNumberOp : Parser NumberOp
parseNumberOp =
    oneOf
        [ P.map (\_ -> EqNum) (symbol "=")
        , P.map (\_ -> NotEqNum) (symbol "!=")
        , P.map (\_ -> GTE) (symbol ">=")
        , P.map (\_ -> GT) (symbol ">")
        , P.map (\_ -> LTE) (symbol "<=")
        , P.map (\_ -> LT) (symbol "<")
        ]


parseSizeSuffix : Parser SizeSuffix
parseSizeSuffix =
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


parseShortcutNameContains : Parser Expr
parseShortcutNameContains =
    P.map Name <|
        P.succeed Contains
            |. symbol "\""
            |= (P.chompUntil "\"" |> P.getChompedString |> P.andThen toCs)
            |. symbol "\""


parseShortcutNameRegex : Parser Expr
parseShortcutNameRegex =
    P.map Name <|
        P.map Matches <|
            (P.chompUntilEndOr " " |> P.getChompedString |> P.andThen toRe)



-- ALIASES


stuck : Expr
stuck =
    let
        not_done =
            Done LT 100

        down0 =
            DownRate EqNum 0 Nothing

        not_stopped =
            Status NotEqStatus Model.Torrent.Stopped

        not_paused =
            Status NotEqStatus Model.Torrent.Paused

        not_stopped_or_paused =
            AndExpr not_stopped not_paused
    in
    AndExpr (AndExpr not_done down0) not_stopped_or_paused



-- MISC


toCs : String -> Parser CaseSensititivy
toCs str =
    -- this enables smart case search.
    -- If the term has any uppercase, store it under CaseSensitive.
    -- later we will not do toLower on the target string to make this work.
    if String.any Char.isUpper str then
        P.succeed <| CaseSensitive str

    else
        P.succeed <| CaseInsensitive str


toRe : String -> Parser Regex
toRe str =
    let
        caseInsensitive =
            not (String.any Char.isUpper str)
    in
    str
        |> Regex.fromStringWith
            { caseInsensitive = caseInsensitive
            , multiline = False
            }
        |> Maybe.map P.succeed
        |> Maybe.withDefault (P.problem ("invalid regexp " ++ str))


translateRelativeTime : Int -> RelativeTimeSuffix -> Int
translateRelativeTime i suffix =
    case suffix of
        Second ->
            i

        Minute ->
            i * 60

        Hour ->
            i * 3600

        Day ->
            i * 86400

        Week ->
            i * 604800

        Year ->
            i * 31536000


translateMonthIntToPart : Int -> Time.Month
translateMonthIntToPart month =
    case month of
        1 ->
            Time.Jan

        2 ->
            Time.Feb

        3 ->
            Time.Mar

        4 ->
            Time.Apr

        5 ->
            Time.May

        6 ->
            Time.Jun

        7 ->
            Time.Jul

        8 ->
            Time.Aug

        9 ->
            Time.Sep

        10 ->
            Time.Oct

        11 ->
            Time.Nov

        _ ->
            Time.Dec
