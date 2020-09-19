module Coders.Torrent exposing (decoder, listDecoder)

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
    -- this order MUST match Subscriptions.elm#getTorrentsRequest
    --
    -- this gets fed to internalDecoder (below) which populates a Torrent
    D.succeed internalDecoder
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
        -- downloadedBytes
        |> custom (D.index 6 D.int)
        -- downloadRate
        |> custom (D.index 7 D.int)
        -- uploadedBytes
        |> custom (D.index 8 D.int)
        -- uploadRate
        |> custom (D.index 9 D.int)
        -- peersConnected
        |> custom (D.index 10 D.int)
        -- label
        |> custom (D.index 11 D.string)
        |> Pipeline.resolve


internalDecoder : String -> String -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> String -> D.Decoder Torrent
internalDecoder hash name size creationTime startedTime finishedTime downloadedBytes downloadRate uploadedBytes uploadRate peersConnected label =
    let
        -- after decoder is done, we can add further internal fields here
        donePercent =
            -- XXX this may change if a torrent is hashing?
            (toFloat downloadedBytes / toFloat size) * 100.0
    in
    D.succeed <|
        Torrent
            hash
            name
            size
            creationTime
            startedTime
            finishedTime
            downloadedBytes
            downloadRate
            uploadedBytes
            uploadRate
            peersConnected
            label
            donePercent
