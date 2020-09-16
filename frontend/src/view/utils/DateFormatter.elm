module View.Utils.DateFormatter exposing (..)

import DateFormat
import Time exposing (Posix, Zone, utc)



--- TODO: config..


formatter : Zone -> Posix -> String
formatter =
    DateFormat.format
        [ DateFormat.dayOfMonthFixed
        , DateFormat.text "."
        , DateFormat.monthFixed
        , DateFormat.text "."
        , DateFormat.yearNumber
        , DateFormat.text " "
        , DateFormat.hourMilitaryFixed
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        , DateFormat.text ":"
        , DateFormat.secondFixed
        ]


timezone : Zone
timezone =
    utc


posixTime : Int -> Posix
posixTime int =
    Time.millisToPosix (int * 1000)


format : Int -> String
format input =
    let
        time =
            posixTime input
    in
    formatter timezone time
