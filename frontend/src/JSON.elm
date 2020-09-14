module JSON exposing (..)

import Json.Decode as D
import Json.Encode as E
import Torrent exposing (Torrent)


type DecodedData
    = Torrents (List Torrent)
    | Error String


decodeString : String -> Result D.Error DecodedData
decodeString =
    D.decodeString websocketMessageDecoder


websocketMessageDecoder : D.Decoder DecodedData
websocketMessageDecoder =
    D.oneOf
        [ errorDecoder
        , torrentListDecoder
        ]


errorDecoder : D.Decoder DecodedData
errorDecoder =
    D.map Error <|
        D.field "error" D.string



-- TORRENTS; move to Torrent.elm?


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


torrentListDecoder : D.Decoder DecodedData
torrentListDecoder =
    D.map Torrents <|
        D.field "data" <|
            D.list torrentDecoder


torrentDecoder : D.Decoder Torrent
torrentDecoder =
    D.map3 Torrent
        (D.index 0 D.string)
        (D.index 1 D.string)
        (D.index 2 D.int)
