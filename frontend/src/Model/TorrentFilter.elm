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


type StringOp
    = EqStr CaseSensititivy
    | NotEqStr CaseSensititivy
    | Contains CaseSensititivy
    | NotContains CaseSensititivy
    | Matches Regex
    | NotMatches Regex


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


type Operator
    = And
    | Or


type Expr
    = AndFilter Expr Expr
    | OrFilter Expr Expr
    | Unset
    | Name StringOp
    | Label StringOp
    | Size NumberOp Int SizeSuffix
    | Downloaded NumberOp Int SizeSuffix
    | Uploaded NumberOp Int SizeSuffix
    | DownRate NumberOp Int SizeSuffix
    | UpRate NumberOp Int SizeSuffix
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


torrentMatches : Torrent -> TorrentFilter -> Bool
torrentMatches torrent filter =
    case filter.filter of
        Ok e ->
            torrentMatchesComponent torrent e

        Err _ ->
            False


torrentMatchesComponent : Torrent -> Expr -> Bool
torrentMatchesComponent torrent filter =
    case filter of
        Unset ->
            True

        AndFilter e1 e2 ->
            torrentMatchesComponent torrent e1
                && torrentMatchesComponent torrent e2

        OrFilter e1 e2 ->
            torrentMatchesComponent torrent e1
                || torrentMatchesComponent torrent e2

        Name op ->
            stringMatcher torrent .name op

        Label op ->
            stringMatcher torrent .label op

        Size op num suffix ->
            sizeSuffixMatcher torrent .size op num suffix

        Downloaded op num suffix ->
            sizeSuffixMatcher torrent .downloadedBytes op num suffix

        Uploaded op num suffix ->
            sizeSuffixMatcher torrent .uploadedBytes op num suffix

        DownRate op num suffix ->
            sizeSuffixMatcher torrent .downloadRate op num suffix

        UpRate op num suffix ->
            sizeSuffixMatcher torrent .uploadRate op num suffix

        SeedersConnected op num ->
            numberMatcher torrent .seedersConnected op num

        SeedersTotal op num ->
            numberMatcher torrent .seedersTotal op num

        PeersConnected op num ->
            numberMatcher torrent .peersConnected op num

        PeersTotal op num ->
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


reMatch : Regex -> String -> Bool
reMatch re str =
    Regex.contains re str


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
                (\( op, newExpr ) ->
                    expressionHelp (( expr, op ) :: revOps) newExpr
                )
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
            finalize otherRevOps (AndFilter expr finalExpr)

        ( expr, Or ) :: otherRevOps ->
            OrFilter (finalize otherRevOps expr) finalExpr


parseExpr : Parser Expr
parseExpr =
    oneOf
        [ P.map (\_ -> Unset) P.end
        , parseShortcutNameContains
        , parseFieldOp
        , parseShortcutNameRegex
        ]


parseFieldOp : Parser Expr
parseFieldOp =
    oneOf [ parseStringField, parseSizeField, parseIntField, parseFloatOp ]


parseStringField : Parser Expr
parseStringField =
    oneOf
        [ P.map (\_ -> Name) (keyword "name")
        , P.map (\_ -> Label) (keyword "label")
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
        |= (P.chompUntilEndOr "\"" |> P.getChompedString |> P.andThen toCs)
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
        |= (P.chompUntilEndOr " " |> P.getChompedString |> P.andThen toCs)


parseReStringOp : Parser StringOp
parseReStringOp =
    oneOf
        [ P.map (\_ -> Matches) (symbol "~")
        , P.map (\_ -> NotMatches) (symbol "!~")
        ]
        |. P.spaces
        |= (P.chompUntilEndOr " " |> P.getChompedString |> P.andThen toRe)


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


parseFloatOp : Parser Expr
parseFloatOp =
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
        , P.map (\_ -> GT) (symbol ">")
        , P.map (\_ -> GTE) (symbol ">=")
        , P.map (\_ -> LT) (symbol "<")
        , P.map (\_ -> LTE) (symbol "<=")
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
