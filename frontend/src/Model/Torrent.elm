module Model.Torrent exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as Pipeline exposing (custom)
import List.Extra


type SortDirection
    = Asc
    | Desc


type Sort
    = SortBy Attribute SortDirection


type Status
    = Seeding
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
    , isOpen : Bool
    , isActive : Bool
    , hashing : HashingStatus
    , seedersConnected : Int
    , seedersTotal : Int
    , peersConnected : Int
    , peersTotal : Int
    , label : String

    -- custom local vars, not from JSON
    , donePercent : Float
    }



-- SORTING


sort : Sort -> List Torrent -> List String
sort sortBy torrents =
    let
        comparators =
            List.map comparator (resolveSort sortBy)
    in
    List.map .hash <|
        List.foldl List.Extra.stableSortWith torrents comparators


resolveSort : Sort -> List Sort
resolveSort sortBy =
    -- if sortBy is a special case, decide what to actually sort by
    case sortBy of
        SortBy Seeders direction ->
            [ SortBy SeedersTotal direction, SortBy SeedersConnected direction ]

        SortBy Peers direction ->
            [ SortBy PeersTotal direction, SortBy PeersConnected direction ]

        _ ->
            [ sortBy ]


comparator : Sort -> Torrent -> Torrent -> Order
comparator sortBy a b =
    case sortBy of
        SortBy Status direction ->
            maybeReverse direction <| statusCmp a b

        SortBy Name direction ->
            maybeReverse direction <| cmp a b .name

        SortBy Size direction ->
            maybeReverse direction <| cmp a b .size

        SortBy CreationTime direction ->
            maybeReverse direction <| cmp a b .creationTime

        SortBy StartedTime direction ->
            maybeReverse direction <| cmp a b .startedTime

        SortBy FinishedTime direction ->
            maybeReverse direction <| cmp a b .finishedTime

        SortBy DownloadedBytes direction ->
            maybeReverse direction <| cmp a b .downloadedBytes

        SortBy DownloadRate direction ->
            maybeReverse direction <| cmp a b .downloadRate

        SortBy UploadedBytes direction ->
            maybeReverse direction <| cmp a b .uploadedBytes

        SortBy UploadRate direction ->
            maybeReverse direction <| cmp a b .uploadRate

        SortBy Seeders direction ->
            -- NOTREACHED
            maybeReverse direction <| cmp a b .seedersConnected

        SortBy SeedersConnected direction ->
            maybeReverse direction <| cmp a b .seedersConnected

        SortBy SeedersTotal direction ->
            maybeReverse direction <| cmp a b .seedersTotal

        SortBy Peers direction ->
            -- NOTREACHED
            maybeReverse direction <| cmp a b .peersConnected

        SortBy PeersConnected direction ->
            maybeReverse direction <| cmp a b .peersConnected

        SortBy PeersTotal direction ->
            maybeReverse direction <| cmp a b .peersTotal

        SortBy Label direction ->
            maybeReverse direction <| cmp a b .label

        SortBy DonePercent direction ->
            maybeReverse direction <| cmp a b .donePercent


statusCmp : Torrent -> Torrent -> Order
statusCmp a b =
    {- convert a.status and b.status to ints so they're comparable -}
    let
        a1 =
            statusToInt a.status

        b1 =
            statusToInt b.status
    in
    if a1 == b1 then
        EQ

    else if a1 > b1 then
        GT

    else
        LT


cmp : Torrent -> Torrent -> (Torrent -> comparable) -> Order
cmp a b method =
    let
        a1 =
            method a

        b1 =
            method b
    in
    if a1 == b1 then
        EQ

    else if a1 > b1 then
        GT

    else
        LT


maybeReverse : SortDirection -> Order -> Order
maybeReverse direction order =
    case direction of
        Asc ->
            order

        Desc ->
            case order of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT



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
        -- seedersConnected
        |> custom (D.index 13 D.int)
        -- seedersTotal
        |> custom (D.index 14 D.string)
        -- peersConnected
        |> custom (D.index 15 D.int)
        -- peersTotal
        |> custom (D.index 16 D.string)
        -- label
        |> custom (D.index 17 D.string)
        |> Pipeline.resolve


internalDecoder : String -> String -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Bool -> Bool -> HashingStatus -> Int -> String -> Int -> String -> String -> D.Decoder Torrent
internalDecoder hash name size creationTime startedTime finishedTime downloadedBytes downloadRate uploadedBytes uploadRate isOpen isActive hashing seedersConnected seedersTotal peersConnected peersTotal label =
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
            (Maybe.withDefault 0 <| String.toInt peersTotal)
            label
            donePercent


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


statusToInt : Status -> Int
statusToInt status =
    {- convert Status to a comparable value for sorting -}
    case status of
        Seeding ->
            0

        Downloading ->
            1

        Paused ->
            2

        Stopped ->
            3

        Hashing ->
            4



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


keyToAttribute : String -> Attribute
keyToAttribute str =
    --- XXX: should be a Maybe so NOT DONE can return Nothing?
    case str of
        "status" ->
            Status

        "name" ->
            Name

        "size" ->
            Size

        "creationTime" ->
            CreationTime

        "startedTime" ->
            StartedTime

        "finishedTime" ->
            FinishedTime

        "downloadedBytes" ->
            DownloadedBytes

        "downloadRate" ->
            DownloadRate

        "uploadedBytes" ->
            UploadedBytes

        "uploadRate" ->
            UploadRate

        "seedersConnected" ->
            SeedersConnected

        "seeders" ->
            Seeders

        "seedersTotal" ->
            SeedersTotal

        "peers" ->
            Peers

        "peersConnected" ->
            PeersConnected

        "peersTotal" ->
            PeersTotal

        "label" ->
            Label

        "donePercent" ->
            DonePercent

        _ ->
            Debug.todo "NOT DONE :("
