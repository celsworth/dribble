module JSON exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Torrent exposing (..)


type DecodedData
    = Torrents (List Torrent)
    | Err String


decodeString : String -> Result D.Error DecodedData
decodeString =
    D.decodeString websocketMessageDecoder


websocketMessageDecoder : Decoder DecodedData
websocketMessageDecoder =
    D.oneOf
        [ errorDecoder
        , torrentListDecoder
        ]


errorDecoder : Decoder DecodedData
errorDecoder =
    D.map Err <|
        D.field "error" D.string



-- TORRENTS


getTorrentsRequest : String
getTorrentsRequest =
    E.encode 0 <|
        E.object
            [ ( "command"
              , E.list E.string
                    [ "d.multicall2"
                    , ""
                    , "main"
                    , "d.hash="
                    , "d.name="
                    , "d.size_bytes="
                    ]
              )
            ]


torrentListDecoder : Decoder DecodedData
torrentListDecoder =
    D.map Torrents <|
        D.field "data" <|
            D.list torrentDecoder


torrentDecoder : Decoder Torrent
torrentDecoder =
    D.map3 Torrent
        (D.index 0 D.string)
        (D.index 1 D.string)
        (D.index 2 D.int)
