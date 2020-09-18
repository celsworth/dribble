module Model.TorrentSorter exposing (..)

import Model exposing (..)


sort : Sort -> List Torrent -> List String
sort sortBy torrents =
    List.map .hash <|
        List.sortWith (comparator <| sortBy) torrents


comparator : Sort -> Torrent -> Torrent -> Order
comparator sortBy a b =
    case sortBy of
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

        SortBy PeersConnected direction ->
            maybeReverse direction <| torrentCmp a b .peersConnected

        SortBy Label direction ->
            maybeReverse direction <| torrentCmp a b .label

        SortBy DonePercent direction ->
            maybeReverse direction <| torrentCmp a b .donePercent


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
