module Model.TorrentDecoder exposing (decoder, listDecoder)

import Json.Decode as D
import Json.Decode.Pipeline as Pipeline exposing (custom)
import Model exposing (..)


listDecoder : D.Decoder DecodedData
listDecoder =
    D.map TorrentsReceived <|
        D.field "data" <|
            D.list decoder


decoder : D.Decoder Torrent
decoder =
    D.succeed Torrent
        -- hash
        |> custom (D.index 0 D.string)
        -- name
        |> custom (D.index 1 D.string)
        -- size
        |> custom (D.index 2 D.int)
        -- creationTime
        |> custom (D.index 3 D.int)
        -- startedTime
        |> custom (D.index 4 D.int)
        -- finishedTime
        |> custom (D.index 5 D.int)
        -- uploadedBytes
        |> custom (D.index 6 D.int)
        -- uploadRate
        |> custom (D.index 7 D.int)
        -- downloadedBytes
        |> custom (D.index 8 D.int)
        -- downloadRate
        |> custom (D.index 9 D.int)
        -- label
        |> custom (D.index 10 D.string)
