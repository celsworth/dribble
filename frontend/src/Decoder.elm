module Decoder exposing (..)

import Json.Decode as JD exposing (Decoder, field, int, string)
import Torrent exposing (..)


type DecodedData
    = Torrents (List Torrent)
    | Err String


decodeString : String -> Result JD.Error DecodedData
decodeString =
    JD.decodeString websocketMessageDecoder


websocketMessageDecoder : Decoder DecodedData
websocketMessageDecoder =
    JD.oneOf
        [ errorDecoder
        , torrentListDecoder
        ]


errorDecoder : Decoder DecodedData
errorDecoder =
    JD.map Err <|
        field "error" string


torrentListDecoder : Decoder DecodedData
torrentListDecoder =
    JD.map Torrents <|
        field "data" <|
            field "torrents" <|
                JD.list torrentDecoder


torrentDecoder : Decoder Torrent
torrentDecoder =
    JD.map3 Torrent
        (field "hash" string)
        (field "name" string)
        (field "test" int)
