module Model.Torrent exposing (..)

import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline as Pipeline exposing (custom)
import Json.Encode as E


type Status
    = Seeding
    | Errored
    | Downloading
    | Paused
    | Stopped
    | Hashing


type HashingStatus
    = NotHashing
    | InitialHash
    | FinishHash
    | Rehash


type Attribute
    = Status
    | Name
    | Size
    | CreationTime
    | StartedTime
    | FinishedTime
    | DownloadedBytes
    | DownloadRate
    | UploadedBytes
    | UploadRate
    | Ratio
    | Seeders
    | SeedersConnected
    | SeedersTotal
    | Peers
    | PeersConnected
    | PeersTotal
    | Label
    | DonePercent


type alias Torrent =
    { status : Status
    , hash : String
    , name : String
    , size : Int
    , creationTime : Int
    , startedTime : Int
    , finishedTime : Int
    , downloadedBytes : Int
    , downloadRate : Int
    , uploadedBytes : Int
    , uploadRate : Int
    , ratio : Float
    , isOpen : Bool
    , isActive : Bool
    , hashing : HashingStatus
    , message : String
    , seedersConnected : Int
    , seedersTotal : Int
    , peersConnected : Int
    , peersTotal : Int
    , label : String

    -- custom local vars, not from JSON
    , donePercent : Float
    }


type alias TorrentsByHash =
    Dict String Torrent



-- JSON ENCODER


encodeAttribute : Attribute -> E.Value
encodeAttribute attribute =
    E.string <| attributeToKey attribute



-- JSON DECODER


listDecoder : D.Decoder (List Torrent)
listDecoder =
    D.list decoder


decoder : D.Decoder Torrent
decoder =
    -- this order MUST match Model/Rtorrent.elm #getTorrentFields
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
        -- message
        |> custom (D.index 13 D.string)
        -- seedersConnected
        |> custom (D.index 14 D.int)
        -- seedersTotal
        |> custom (D.index 15 D.string)
        -- peersConnected
        |> custom (D.index 16 D.int)
        -- peersTotal
        |> custom (D.index 17 D.string)
        -- label
        |> custom (D.index 18 D.string)
        |> Pipeline.resolve


internalDecoder : String -> String -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Bool -> Bool -> HashingStatus -> String -> Int -> String -> Int -> String -> String -> D.Decoder Torrent
internalDecoder hash name size creationTime startedTime finishedTime downloadedBytes downloadRate uploadedBytes uploadRate isOpen isActive hashing message seedersConnected seedersTotal peersConnected peersTotal label =
    let
        -- after decoder is done, we can add further internal fields here
        donePercent =
            (toFloat downloadedBytes / toFloat size) * 100.0

        done =
            downloadedBytes == size

        status =
            resolveStatus message hashing isOpen isActive done

        ratio =
            toFloat uploadedBytes / toFloat downloadedBytes
    in
    D.succeed <|
        Torrent
            status
            hash
            name
            size
            (creationTime * 1000)
            (startedTime * 1000)
            (finishedTime * 1000)
            downloadedBytes
            downloadRate
            uploadedBytes
            uploadRate
            ratio
            isOpen
            isActive
            hashing
            message
            seedersConnected
            (Maybe.withDefault 0 <| String.toInt seedersTotal)
            peersConnected
            (Maybe.withDefault 0 <| String.toInt peersTotal)
            label
            donePercent


resolveStatus : String -> HashingStatus -> Bool -> Bool -> Bool -> Status
resolveStatus message hashing isOpen isActive done =
    case hashing of
        NotHashing ->
            case message of
                "" ->
                    case ( isOpen, isActive, done ) of
                        ( True, True, True ) ->
                            Seeding

                        ( True, True, False ) ->
                            Downloading

                        ( True, False, _ ) ->
                            Paused

                        ( False, _, _ ) ->
                            Stopped

                _ ->
                    Errored

        _ ->
            Hashing


attributeDecoder : D.Decoder Attribute
attributeDecoder =
    D.string
        |> D.andThen
            (\input ->
                case keyToAttribute input of
                    Just a ->
                        D.succeed <| a

                    Nothing ->
                        D.fail <| "unknown torrent key " ++ input
            )


intToBoolDecoder : D.Decoder Bool
intToBoolDecoder =
    -- this probably wants to move up to a set of generic decoders
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



-- MISC


infiniteToFloat : Float -> Float
infiniteToFloat ratio =
    case ( isNaN ratio, isInfinite ratio ) of
        ( True, _ ) ->
            -- keep NaN at the bottom
            -1

        ( _, True ) ->
            -- keep infinite at the top
            99999999999

        ( _, _ ) ->
            ratio


statusToInt : Status -> Int
statusToInt status =
    {- convert Status to a comparable value for sorting -}
    case status of
        Seeding ->
            0

        Errored ->
            1

        Downloading ->
            2

        Paused ->
            3

        Stopped ->
            4

        Hashing ->
            5



-- ATTRIBUTE ACCCESSORS ETC


attributeToKey : Attribute -> String
attributeToKey attribute =
    case attribute of
        Status ->
            "status"

        Name ->
            "name"

        Size ->
            "size"

        CreationTime ->
            "creationTime"

        StartedTime ->
            "startedTime"

        FinishedTime ->
            "finishedTime"

        DownloadedBytes ->
            "downloadedBytes"

        DownloadRate ->
            "downloadRate"

        UploadedBytes ->
            "uploadedBytes"

        UploadRate ->
            "uploadRate"

        Ratio ->
            "ratio"

        Seeders ->
            "seeders"

        SeedersConnected ->
            "seedersConnected"

        SeedersTotal ->
            "seedersTotal"

        Peers ->
            "peers"

        PeersConnected ->
            "peersConnected"

        PeersTotal ->
            "peersTotal"

        Label ->
            "label"

        DonePercent ->
            "donePercent"


keyToAttribute : String -> Maybe Attribute
keyToAttribute str =
    case str of
        "status" ->
            Just Status

        "name" ->
            Just Name

        "size" ->
            Just Size

        "creationTime" ->
            Just CreationTime

        "startedTime" ->
            Just StartedTime

        "finishedTime" ->
            Just FinishedTime

        "downloadedBytes" ->
            Just DownloadedBytes

        "downloadRate" ->
            Just DownloadRate

        "uploadedBytes" ->
            Just UploadedBytes

        "uploadRate" ->
            Just UploadRate

        "ratio" ->
            Just Ratio

        "seedersConnected" ->
            Just SeedersConnected

        "seeders" ->
            Just Seeders

        "seedersTotal" ->
            Just SeedersTotal

        "peers" ->
            Just Peers

        "peersConnected" ->
            Just PeersConnected

        "peersTotal" ->
            Just PeersTotal

        "label" ->
            Just Label

        "donePercent" ->
            Just DonePercent

        _ ->
            Nothing


attributeToTableHeaderId : Attribute -> String
attributeToTableHeaderId attribute =
    "th-torrentAttribute-" ++ attributeToKey attribute


attributeToTableHeaderString : Attribute -> String
attributeToTableHeaderString attribute =
    case attribute of
        Status ->
            {- force #ta-ta-torrentStatus .size .content to
               have height so it can be clicked on
            -}
            "\u{00A0}"

        CreationTime ->
            "Created"

        StartedTime ->
            "Started"

        FinishedTime ->
            "Finished"

        DownloadRate ->
            "Down"

        UploadRate ->
            "Up"

        _ ->
            attributeToString attribute


attributeToString : Attribute -> String
attributeToString attribute =
    case attribute of
        Status ->
            "Status"

        Name ->
            "Name"

        Size ->
            "Size"

        CreationTime ->
            "Creation Time"

        StartedTime ->
            "Started Time"

        FinishedTime ->
            "Finished Time"

        DownloadedBytes ->
            "Downloaded"

        DownloadRate ->
            "Download Rate"

        UploadedBytes ->
            "Uploaded"

        UploadRate ->
            "Upload Rate"

        Ratio ->
            "Ratio"

        SeedersConnected ->
            "Seeders Connected"

        Seeders ->
            "Seeders"

        SeedersTotal ->
            "Seeders Total"

        Peers ->
            "Peers"

        PeersConnected ->
            "Peers Connected"

        PeersTotal ->
            "Peers Total"

        Label ->
            "Label"

        DonePercent ->
            "Done"


attributeTextAlignment : Attribute -> Maybe String
attributeTextAlignment attribute =
    case attribute of
        Size ->
            Just "text-right"

        DownloadedBytes ->
            Just "text-right"

        DownloadRate ->
            Just "text-right"

        UploadedBytes ->
            Just "text-right"

        UploadRate ->
            Just "text-right"

        CreationTime ->
            Just "text-right"

        StartedTime ->
            Just "text-right"

        FinishedTime ->
            Just "text-right"

        Ratio ->
            Just "text-right"

        Seeders ->
            Just "text-right"

        SeedersConnected ->
            Just "text-right"

        SeedersTotal ->
            Just "text-right"

        Peers ->
            Just "text-right"

        PeersConnected ->
            Just "text-right"

        PeersTotal ->
            Just "text-right"

        _ ->
            Nothing
