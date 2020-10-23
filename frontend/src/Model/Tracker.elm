module Model.Tracker exposing (..)

import Parser as P
    exposing
        ( (|.)
        , (|=)
        , Parser
        , Step(..)
        , oneOf
        , symbol
        )


type alias Tracker =
    { url : String
    }


domainFromURL : String -> String
domainFromURL str =
    P.run parseDomain str
        |> Result.map splitDomain
        |> Result.withDefault "???"


splitDomain : String -> String
splitDomain str =
    -- "a.b.c.d" -> "c.d"
    --
    -- this is naive, will not cope with stuff like bar.co.uk
    str
        |> String.split "."
        |> List.reverse
        |> List.take 2
        |> List.reverse
        |> String.join "."


parseDomain : Parser String
parseDomain =
    P.succeed identity
        |. oneOf [ symbol "http://", symbol "https://" ]
        |= (P.chompWhile (\s -> s /= ':' && s /= '/') |> P.getChompedString)
