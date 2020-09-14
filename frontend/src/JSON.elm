module JSON exposing (..)

import Json.Decode as D
import Json.Encode as E
import Model exposing (..)
import Model.TorrentDecoder as TorrentDecoder


decodeString : String -> Result D.Error DecodedData
decodeString =
    D.decodeString websocketMessageDecoder


websocketMessageDecoder : D.Decoder DecodedData
websocketMessageDecoder =
    D.oneOf
        [ errorDecoder
        , TorrentDecoder.listDecoder
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
