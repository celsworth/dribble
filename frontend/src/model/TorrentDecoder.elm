module Model.TorrentDecoder exposing (decoder, listDecoder)

import Json.Decode as D
import Model exposing (..)


listDecoder : D.Decoder DecodedData
listDecoder =
    D.map Torrents <|
        D.field "data" <|
            D.list decoder


decoder : D.Decoder Torrent
decoder =
    D.map3 Torrent
        (D.index 0 D.string)
        (D.index 1 D.string)
        (D.index 2 D.int)
