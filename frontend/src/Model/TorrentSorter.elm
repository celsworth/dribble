module Model.TorrentSorter exposing (..)

import List.Extra
import Model exposing (..)
import Model.Utils.TorrentStatus


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



{-
    -- {{{ previous naive implementation of sort
    sort : Sort -> List Torrent -> List String
    sort sortBy torrents =
      List.map .hash <|
        case sortBy of
          SortBy Seeders direction ->
            torrents
            |> List.sortWith (comparator <| SortBy SeedersTotal direction)
            |> List.Extra.stableSortWith (comparator <| SortBy SeedersConnected direction)

          SortBy Peers direction ->
            torrents
            |> List.sortWith (comparator <| SortBy PeersTotal direction)
            |> List.Extra.stableSortWith (comparator <| SortBy PeersConnected direction)

          _ ->
            torrents
            |> List.sortWith (comparator <| sortBy)

   -- }}}
-}


comparator : Sort -> Torrent -> Torrent -> Order
comparator sortBy a b =
    case sortBy of
        SortBy TorrentStatus direction ->
            maybeReverse direction <| torrentStatusCmp a b

        SortBy Name direction ->
            maybeReverse direction <| torrentCmp a b .name

        SortBy Size direction ->
            maybeReverse direction <| torrentCmp a b .size

        SortBy CreationTime direction ->
            maybeReverse direction <| torrentCmp a b .creationTime

        SortBy StartedTime direction ->
            maybeReverse direction <| torrentCmp a b .startedTime

        SortBy FinishedTime direction ->
            maybeReverse direction <| torrentCmp a b .finishedTime

        SortBy DownloadedBytes direction ->
            maybeReverse direction <| torrentCmp a b .downloadedBytes

        SortBy DownloadRate direction ->
            maybeReverse direction <| torrentCmp a b .downloadRate

        SortBy UploadedBytes direction ->
            maybeReverse direction <| torrentCmp a b .uploadedBytes

        SortBy UploadRate direction ->
            maybeReverse direction <| torrentCmp a b .uploadRate

        SortBy Seeders direction ->
            -- NOTREACHED
            maybeReverse direction <| torrentCmp a b .seedersConnected

        SortBy SeedersConnected direction ->
            maybeReverse direction <| torrentCmp a b .seedersConnected

        SortBy SeedersTotal direction ->
            maybeReverse direction <| torrentCmp a b .seedersTotal

        SortBy Peers direction ->
            -- NOTREACHED
            maybeReverse direction <| torrentCmp a b .peersConnected

        SortBy PeersConnected direction ->
            maybeReverse direction <| torrentCmp a b .peersConnected

        SortBy PeersTotal direction ->
            maybeReverse direction <| torrentCmp a b .peersTotal

        SortBy Label direction ->
            maybeReverse direction <| torrentCmp a b .label

        SortBy DonePercent direction ->
            maybeReverse direction <| torrentCmp a b .donePercent


torrentStatusCmp : Torrent -> Torrent -> Order
torrentStatusCmp a b =
    {- convert a.status and b.status to ints so they're comparable -}
    let
        a1 =
            Model.Utils.TorrentStatus.toInt a.status

        b1 =
            Model.Utils.TorrentStatus.toInt b.status
    in
    if a1 == b1 then
        EQ

    else if a1 > b1 then
        GT

    else
        LT


torrentCmp : Torrent -> Torrent -> (Torrent -> comparable) -> Order
torrentCmp a b method =
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
