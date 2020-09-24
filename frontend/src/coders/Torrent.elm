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
    -- this order MUST match coders/Base.elm#getTorrentFields
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
        -- open
        |> custom (D.index 10 intToBoolDecoder)
        -- active
        |> custom (D.index 11 intToBoolDecoder)
        -- hashing
        |> custom (D.index 12 intToHashingStatusDecoder)
        -- seedersConnected
        |> custom (D.index 13 D.int)
        -- seedersTotal
        |> custom (D.index 14 D.string)
        -- peersConnected
        |> custom (D.index 15 D.int)
        -- label
        |> custom (D.index 16 D.string)
        |> Pipeline.resolve


internalDecoder : String -> String -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Bool -> Bool -> HashingStatus -> Int -> String -> Int -> String -> D.Decoder Torrent
internalDecoder hash name size creationTime startedTime finishedTime downloadedBytes downloadRate uploadedBytes uploadRate isOpen isActive hashing seedersConnected seedersTotal peersConnected label =
    let
        -- after decoder is done, we can add further internal fields here
        donePercent =
            (toFloat downloadedBytes / toFloat size) * 100.0

        done =
            downloadedBytes == size

        status =
            if hashing /= NotHashing then
                Hashing

            else
                case ( isOpen, isActive, done ) of
                    ( True, True, True ) ->
                        Seeding

                    ( True, True, False ) ->
                        Downloading

                    ( True, False, _ ) ->
                        Paused

                    ( False, _, _ ) ->
                        Stopped
    in
    D.succeed <|
        Torrent
            status
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
            isOpen
            isActive
            hashing
            seedersConnected
            (Maybe.withDefault 0 <| String.toInt seedersTotal)
            peersConnected
            label
            donePercent


intToBoolDecoder : D.Decoder Bool
intToBoolDecoder =
    D.int
        |> D.andThen
            (\input ->
                case input of
                    0 ->
                        D.succeed False

                    1 ->
                        D.succeed True

                    _ ->
                        D.fail <| "cannot convert to bool: " ++ String.fromInt input
            )


intToHashingStatusDecoder : D.Decoder HashingStatus
intToHashingStatusDecoder =
    D.int
        |> D.andThen
            (\input ->
                case input of
                    0 ->
                        D.succeed NotHashing

                    1 ->
                        D.succeed InitialHash

                    2 ->
                        D.succeed FinishHash

                    3 ->
                        D.succeed Rehash

                    _ ->
                        D.fail <| "cannot convert to HashingStatus: " ++ String.fromInt input
            )
