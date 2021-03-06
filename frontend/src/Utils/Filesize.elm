module Utils.Filesize exposing
    ( format, formatSplit, formatBase2, formatBase2Split, formatWith, formatWithSplit, defaultSettings, Settings, Units(..)
    , decoder, encode
    )

{-| This library converts a file size in bytes into a human readable string.

Examples:

    format 1234 == "1.23 kB"

    format 238674052 == "238.67 MB"

    format 543 == "543 B"

You can either use decimal units (also known as base 10 units, these are the
default) or binary (also called base 2 or IEC units).

Supported decimal units:

  - 1 kilobyte (kB) = 1000 bytes
  - 1 megabyte (MB) = 1000 kilobytes
  - 1 gigabyte (GB) = 1000 megabytes
  - 1 terabyte (TB) = 1000 gigabytes
  - 1 petabyte (PB) = 1000 terabytes
  - 1 exabyte (EB) = 1000 petabyte

Larger decimal units (zettabyte (ZB), yottabyte (YB), ...) are not supported.

Supported binary/IEC units:

  - 1 kibibyte (KiB) = 1024 bytes
  - 1 mebibyte (MiB) = 1024 kibibytes
  - 1 gibibyte (GiB) = 1024 mebibytes
  - 1 tebibyte (TiB) = 1024 gibibytes
  - 1 pebibyte (PiB) = 1024 tebibyte

Larger binary units (exbibyte (EiB), zebibyte (ZiB), yobibytej (YiB), ...)) are
not supported.

For decimal/base 10 units, the number of bytes is divided by 10^3 when going to
the next larger unit. For binary/base 2 units, the number of bytes is divided by
2^10 (1024) each time. (For binary units also see
<https://en.wikipedia.org/wiki/Kibibyte>.)


## Usage

@docs format, formatSplit, formatBase2, formatBase2Split, formatWith, formatWithSplit, defaultSettings, Settings, Units

-}

{--

Originally from <https://github.com/basti1302/elm-human-readable-filesize> v1.2.0

  - modified herein by Chris Elsworth:
      - keep trailing zeroes
      - remove bytes suffix, lowest unit is now KB/KiB
      - default unit is Base2
      - added JSON encoding/decoding

Original license as per <https://github.com/basti1302/elm-human-readable-filesize/blob/master/LICENSE>

Copyright (c) 2016-2017 the elm-human-readable-filsize contributors
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  - Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

  - Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

  - Neither the name of elm-human-readable-filsize nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

--}

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional)
import Json.Encode as E
import Regex exposing (Regex, replaceAtMost)
import Round


{-| The two possible unit types, either decimal/base 10 (kb, MB, GB, ...) or
binary/IEC/base 2 (KiB, MiB, GiB, ...), see above.
-}
type Units
    = Base10
    | Base2


{-| Use a settings record together with `formatWith` to customize the formatting
process. The available options are:

  - `units`: use either decimal or binary/IEC units (the default is to use decimal
    units),
  - `decimalPlaces`: the number of decimal places (digits after the decimal
    separator, the default is 2) and
  - `decimalSeparator`: the decimal separator to use (default ".").

-}
type alias Settings =
    { units : Units
    , decimalPlaces : Int
    , decimalSeparator : String
    }


{-| The default settings. When using `formatWith`, it is recommended to obtain
a settings record with this function and modify the settings to your liking.
-}
defaultSettings : Settings
defaultSettings =
    { units = Base2
    , decimalPlaces = 2
    , decimalSeparator = "."
    }


type alias UnitDefinition =
    { minimumSize : Int
    , divider : Int
    , abbreviation : String
    }


type alias UnitDefinitionList =
    List UnitDefinition


base10UnitList : UnitDefinitionList
base10UnitList =
    [ { divider = 1000, minimumSize = 0, abbreviation = "kB" }
    , { divider = 1000000, minimumSize = 1000000, abbreviation = "MB" }
    , { divider = 1000000000, minimumSize = 1000000000, abbreviation = "GB" }
    , { divider = 1000000000000, minimumSize = 1000000000000, abbreviation = "TB" }
    , { divider = 1000000000000000, minimumSize = 1000000000000000, abbreviation = "PB" }
    , { divider = 1000000000000000000, minimumSize = 1000000000000000000, abbreviation = "EB" }

    -- , { miniumVersion = 1000000000000000000000, abbreviation = "ZB" }
    -- , { miniumVersion = 1000000000000000000000000, abbreviation = "YB" }
    -- , ...
    ]


base2UnitList : UnitDefinitionList
base2UnitList =
    [ { divider = 1024, minimumSize = 0, abbreviation = "KiB" }
    , { divider = 1048576, minimumSize = 1048576, abbreviation = "MiB" }
    , { divider = 1073741824, minimumSize = 1073741824, abbreviation = "GiB" }
    , { divider = 1099511627776, minimumSize = 1099511627776, abbreviation = "TiB" }
    , { divider = 1125899906842624, minimumSize = 1125899906842624, abbreviation = "PiB" }

    -- , ...
    ]


getUnitDefinitionList : Units -> UnitDefinitionList
getUnitDefinitionList units =
    case units of
        Base10 ->
            base10UnitList

        Base2 ->
            base2UnitList


unknownUnit : UnitDefinition
unknownUnit =
    { divider = 1, minimumSize = 1, abbreviation = "?" }


decimalSeparatorRegex : Regex
decimalSeparatorRegex =
    "\\." |> Regex.fromString |> Maybe.withDefault Regex.never


{-| Formats the given file size with the default settings.

Convenience function for

    let
        ( size, unit ) =
            formatWithSplit settings num
    in
    size ++ " " ++ unit

-}
format : Int -> String
format num =
    let
        ( size, unit ) =
            formatWithSplit defaultSettings num
    in
    size ++ " " ++ unit


{-| Formats the given file size with the default settings, returning the number and units separately, in a tuple.
-}
formatSplit : Int -> ( String, String )
formatSplit =
    formatWithSplit defaultSettings


{-| Formats the given file size with the binary/base2/IEC unit.
-}
formatBase2 : Int -> String
formatBase2 =
    formatWith { defaultSettings | units = Base2 }


{-| Formats the given file size with the binary/base2/IEC unit, returning the number and units separately, in a tuple.
-}
formatBase2Split : Int -> ( String, String )
formatBase2Split =
    formatWithSplit { defaultSettings | units = Base2 }


{-| Formats the given file size with the given settings.
-}
formatWith : Settings -> Int -> String
formatWith settings num =
    let
        ( size, unit ) =
            formatWithSplit settings num
    in
    size ++ " " ++ unit


{-| Formats the given file size with the given settings, returning the number and units separately, in a tuple.
-}
formatWithSplit : Settings -> Int -> ( String, String )
formatWithSplit settings num =
    let
        ( num2, negativePrefix ) =
            if num < 0 then
                ( num |> negate, "-" )

            else
                ( num, "" )

        unitDefinitionList =
            getUnitDefinitionList settings.units

        unitDefinition =
            unitDefinitionList
                |> List.filter (\unitDef -> num2 >= unitDef.minimumSize)
                |> List.reverse
                |> List.head
                |> Maybe.withDefault unknownUnit

        formattedNumber =
            toFloat num2
                / toFloat unitDefinition.divider
                |> roundToDecimalPlaces settings
    in
    ( negativePrefix ++ formattedNumber, unitDefinition.abbreviation )


roundToDecimalPlaces : Settings -> Float -> String
roundToDecimalPlaces settings num =
    let
        -- Actually, using Round.round instead of floor would be preferable but
        -- we never want to round from 999.999 to 1000 because then we would
        -- combine the number with the wrong unit (the proper unit has been
        -- calculated before rounding). Maybe we should switch rounding and unit
        -- selection to avoid this?
        rounded =
            Round.floor settings.decimalPlaces num

        withoutTrailingDot =
            if String.endsWith "." rounded then
                String.dropRight 1 rounded

            else
                rounded
    in
    if settings.decimalSeparator == "." then
        withoutTrailingDot

    else
        Regex.replaceAtMost 1
            decimalSeparatorRegex
            (\_ -> settings.decimalSeparator)
            withoutTrailingDot



-- JSON ENCODING


encode : Settings -> E.Value
encode settings =
    E.object
        [ ( "units", encodeUnits settings.units )
        , ( "decimalPlaces", E.int settings.decimalPlaces )
        , ( "decimalSeparator", E.string settings.decimalSeparator )
        ]


encodeUnits : Units -> E.Value
encodeUnits units =
    case units of
        Base2 ->
            E.string "Base2"

        Base10 ->
            E.string "Base10"



-- JSON DECODING


decoder : D.Decoder Settings
decoder =
    D.succeed Settings
        |> optional "units" unitsDecoder defaultSettings.units
        |> optional "decimalPlaces" D.int defaultSettings.decimalPlaces
        |> optional "decimalSeparator" D.string defaultSettings.decimalSeparator


unitsDecoder : D.Decoder Units
unitsDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "Base2" ->
                        D.succeed Base2

                    "Base10" ->
                        D.succeed Base10

                    _ ->
                        D.fail <| "unknown units" ++ input
            )
