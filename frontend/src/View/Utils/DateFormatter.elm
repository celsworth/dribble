module View.Utils.DateFormatter exposing (format)

import DateFormat
import Model exposing (..)
import Time


format : Time.Zone -> Time.Posix -> String
format =
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
