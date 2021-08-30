module Model.Torrent exposing (..)

import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline as Pipeline exposing (custom, required)
import Json.Encode as E
import Model.Sort exposing (SortDirection(..))
import Model.Tracker
import Url


type Status
    = Seeding
    | Active
    | Inactive
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


type Priority
    = Off
    | LowPriority
    | NormalPriority
    | HighPriority


type Sort
    = SortBy Attribute SortDirection


type Attribute
    = Status
    | Name
    | Size
    | FileCount
    | CreationTime
    | AddedTime
    | StartedTime
    | FinishedTime
    | DownloadedBytes
    | DownloadRate
    | UploadedBytes
    | UploadRate
    | SkippedBytes
    | Ratio
    | Seeders
    | Priority
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
    , fileCount : Int
    , creationTime : Int
    , addedTime : Int
    , startedTime : Int
    , finishedTime : Int
    , downloadedBytes : Int
    , downloadRate : Int
    , uploadedBytes : Int
    , uploadRate : Int
    , skippedBytes : Int
    , ratio : Float
    , isOpen : Bool
    , isActive : Bool
    , hashing : HashingStatus
    , message : String
    , priority : Priority
    , seedersConnected : Int
    , seedersTotal : Int
    , peersConnected : Int
    , peersTotal : Int
    , label : String
    , trackerHosts : List String

    -- custom local vars, not from JSON
    , donePercent : Float
    }


type alias TorrentsByHash =
    Dict String Torrent



-- JSON ENCODING


encodeAttribute : Attribute -> E.Value
encodeAttribute attribute =
    E.string <| attributeToKey attribute


encodeSortBy : Sort -> E.Value
encodeSortBy sortBy =
    let
        (SortBy column direction) =
            sortBy
    in
    E.object
        [ ( "column", encodeAttribute column )
        , ( "direction", Model.Sort.encodeSortDirection direction )
        ]



-- JSON DECODER


listDecoder : D.Decoder (List Torrent)
listDecoder =
    D.list decoder


decoder : D.Decoder Torrent
decoder =
    -- this order MUST match Model/Rtorrent.elm #getTorrentFields
    --
    -- this gets fed to internalDecoder (below) to populate a Torrent
    D.succeed internalDecoder
        -- hash
        |> custom (D.index 0 D.string)
        -- name
        |> custom (D.index 1 D.string)
        -- size
        |> custom (D.index 2 D.int)
        -- fileCount
        |> custom (D.index 3 D.int)
        -- creationTime
        |> custom (D.index 4 D.int)
        -- addedTime
        |> custom (D.index 5 D.string)
        -- startedTime
        |> custom (D.index 6 D.int)
        -- finishedTime
        |> custom (D.index 7 D.int)
        -- downloadedBytes
        |> custom (D.index 8 D.int)
        -- downloadRate
        |> custom (D.index 9 D.int)
        -- uploadedBytes
        |> custom (D.index 10 D.int)
        -- uploadRate
        |> custom (D.index 11 D.int)
        -- skippedBytes
        |> custom (D.index 12 D.int)
        -- open
        |> custom (D.index 13 intToBoolDecoder)
        -- active
        |> custom (D.index 14 intToBoolDecoder)
        -- hashing
        |> custom (D.index 15 intToHashingStatusDecoder)
        -- message
        |> custom (D.index 16 D.string)
        -- priority
        |> custom (D.index 17 intToPriorityDecoder)
        -- seedersConnected
        |> custom (D.index 18 D.int)
        -- seedersTotal
        |> custom (D.index 19 D.int)
        -- peersConnected
        |> custom (D.index 20 D.int)
        -- peersTotal
        |> custom (D.index 21 D.int)
        -- label
        |> custom (D.index 22 D.string)
        -- tracker urls -> hosts
        |> custom (D.index 23 <| D.list trackerHostArrayDecoder)
        |> Pipeline.resolve


internalDecoder : String -> String -> Int -> Int -> Int -> String -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Bool -> Bool -> HashingStatus -> String -> Priority -> Int -> Int -> Int -> Int -> String -> List String -> D.Decoder Torrent
internalDecoder hash name size fileCount creationTime addedTime startedTime finishedTime downloadedBytes downloadRate uploadedBytes uploadRate skippedBytes isOpen isActive hashing message priority seedersConnected seedersTotal peersConnected peersTotal label trackerHosts =
    -- further postprocessing of JSON decoding, adding internal fields etc.
    let
        done =
            downloadedBytes == size

        status =
            resolveStatus message hashing isOpen isActive done
    in
    D.succeed <|
        Torrent
            status
            hash
            name
            size
            fileCount
            (creationTime * 1000)
            ((addedTime |> String.trim |> String.toInt |> Maybe.withDefault 0) * 1000)
            (startedTime * 1000)
            (finishedTime * 1000)
            downloadedBytes
            downloadRate
            uploadedBytes
            uploadRate
            skippedBytes
            {- ratio -} (toFloat uploadedBytes / toFloat downloadedBytes)
            isOpen
            isActive
            hashing
            message
            priority
            seedersConnected
            seedersTotal
            peersConnected
            peersTotal
            (Url.percentDecode label |> Maybe.withDefault label)
            trackerHosts
            {- donePercent -} ((toFloat downloadedBytes / toFloat size) * 100.0)


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
                keyToAttribute input
                    |> Maybe.map D.succeed
                    |> Maybe.withDefault (D.fail <| "unknown key ")
            )


sortByDecoder : D.Decoder Sort
sortByDecoder =
    D.succeed SortBy
        |> required "column" attributeDecoder
        |> required "direction" Model.Sort.sortDirectionDecoder


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


intToPriorityDecoder : D.Decoder Priority
intToPriorityDecoder =
    D.int
        |> D.andThen
            (\input ->
                case input of
                    0 ->
                        D.succeed Off

                    1 ->
                        D.succeed LowPriority

                    2 ->
                        D.succeed NormalPriority

                    3 ->
                        D.succeed HighPriority

                    _ ->
                        D.fail <| "cannot convert to Priority: " ++ String.fromInt input
            )


trackerHostArrayDecoder : D.Decoder String
trackerHostArrayDecoder =
    D.map Model.Tracker.domainFromURL <| D.index 0 D.string



-- MISC


priorityToString : Priority -> String
priorityToString priority =
    case priority of
        Off ->
            "off"

        LowPriority ->
            "low"

        NormalPriority ->
            "normal"

        HighPriority ->
            "high"


statusToString : Status -> String
statusToString status =
    case status of
        Seeding ->
            "Seeding"

        Active ->
            "Active"

        Inactive ->
            "Inactive"

        Errored ->
            "Errored"

        Paused ->
            "Paused"

        Stopped ->
            "Stopped"

        Downloading ->
            "Downloading"

        Hashing ->
            "Hashing"


stringToStatus : String -> Maybe Status
stringToStatus string =
    case string of
        "Seeding" ->
            Just Seeding

        "Active" ->
            Just Active

        "Inactive" ->
            Just Inactive

        "Errored" ->
            Just Errored

        "Paused" ->
            Just Paused

        "Stopped" ->
            Just Stopped

        "Downloading" ->
            Just Downloading

        "Hashing" ->
            Just Hashing

        _ ->
            Nothing



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

        FileCount ->
            "fileCount"

        CreationTime ->
            "creationTime"

        AddedTime ->
            "addedTime"

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

        SkippedBytes ->
            "skippedBytes"

        Ratio ->
            "ratio"

        Seeders ->
            "seeders"

        Priority ->
            "priority"

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

        "fileCount" ->
            Just FileCount

        "creationTime" ->
            Just CreationTime

        "addedTime" ->
            Just AddedTime

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

        "skippedBytes" ->
            Just SkippedBytes

        "ratio" ->
            Just Ratio

        "priority" ->
            Just Priority

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

        AddedTime ->
            "Added"

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

        FileCount ->
            "Files"

        CreationTime ->
            "Creation Time"

        AddedTime ->
            "Added Time"

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

        SkippedBytes ->
            "Skipped"

        Ratio ->
            "Ratio"

        Priority ->
            "Priority"

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
