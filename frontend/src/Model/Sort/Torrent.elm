module Model.Sort.Torrent exposing (sort)

import List.Extra
import Model.Sort exposing (SortDirection(..))
import Model.Torrent
    exposing
        ( Attribute(..)
        , Priority(..)
        , Sort(..)
        , Status(..)
        , Torrent
        )


sort : Model.Torrent.Sort -> List Torrent -> List String
sort sortBy torrents =
    let
        comparators =
            List.map (comparator direction) (resolveSort attribute)

        (SortBy attribute direction) =
            sortBy
    in
    List.map .hash <|
        List.foldl List.Extra.stableSortWith torrents comparators


resolveSort : Model.Torrent.Attribute -> List Model.Torrent.Attribute
resolveSort attribute =
    -- if sortBy is a special case, decide what to actually sort by
    case attribute of
        Seeders ->
            [ SeedersTotal
            , SeedersConnected
            ]

        Peers ->
            [ PeersTotal
            , PeersConnected
            ]

        _ ->
            [ attribute ]


comparator : SortDirection -> Model.Torrent.Attribute -> Torrent -> Torrent -> Order
comparator direction attribute a b =
    case attribute of
        Status ->
            -- ends up doing a1 = statusToInt .status a
            maybeReverse direction <| cmp a b (.status >> statusToInt)

        Name ->
            maybeReverse direction <| cmp a b .name

        Size ->
            maybeReverse direction <| cmp a b .size

        CreationTime ->
            maybeReverse direction <| cmp a b .creationTime

        StartedTime ->
            maybeReverse direction <| cmp a b .startedTime

        FinishedTime ->
            maybeReverse direction <| cmp a b .finishedTime

        DownloadedBytes ->
            maybeReverse direction <| cmp a b .downloadedBytes

        DownloadRate ->
            maybeReverse direction <| cmp a b .downloadRate

        UploadedBytes ->
            maybeReverse direction <| cmp a b .uploadedBytes

        UploadRate ->
            maybeReverse direction <| cmp a b .uploadRate

        SkippedBytes ->
            maybeReverse direction <| cmp a b .skippedBytes

        Ratio ->
            maybeReverse direction <| cmp a b (.ratio >> infiniteToFloat)

        Priority ->
            maybeReverse direction <| cmp a b (.priority >> priorityToInt)

        Seeders ->
            -- NOTREACHED
            maybeReverse direction <| cmp a b .seedersConnected

        SeedersConnected ->
            maybeReverse direction <| cmp a b .seedersConnected

        SeedersTotal ->
            maybeReverse direction <| cmp a b .seedersTotal

        Peers ->
            -- NOTREACHED
            maybeReverse direction <| cmp a b .peersConnected

        PeersConnected ->
            maybeReverse direction <| cmp a b .peersConnected

        PeersTotal ->
            maybeReverse direction <| cmp a b .peersTotal

        Label ->
            maybeReverse direction <| cmp a b .label

        DonePercent ->
            maybeReverse direction <| cmp a b .donePercent


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


priorityToInt : Priority -> Int
priorityToInt priority =
    {- convert Priority to a comparable value for sorting -}
    case priority of
        Off ->
            0

        LowPriority ->
            1

        NormalPriority ->
            2

        HighPriority ->
            3
