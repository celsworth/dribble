module Model.Utils.TorrentAttribute exposing (..)

import Model exposing (..)
import Time
import Utils.Filesize
import View.Utils.DateFormatter


attributeToTableHeaderId : TorrentAttribute -> String
attributeToTableHeaderId attribute =
    "th-ta-" ++ attributeToKey attribute


attributeToKey : TorrentAttribute -> String
attributeToKey attribute =
    case attribute of
        TorrentStatus ->
            "torrentStatus"

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


keyToAttribute : String -> TorrentAttribute
keyToAttribute str =
    --- XXX: should be a Maybe so NOT DONE can return Nothing?
    case str of
        "torrentStatus" ->
            TorrentStatus

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



-- return a human readable version of a TorrentAttribute definition.
-- this is used in HTML when there is no other specific method available
-- (eg, we have one for table headers which has shorter strings for some)


attributeToString : TorrentAttribute -> String
attributeToString attribute =
    case attribute of
        TorrentStatus ->
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


attributeToTableHeaderString : TorrentAttribute -> String
attributeToTableHeaderString attribute =
    case attribute of
        TorrentStatus ->
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



-- Given a Torrent and TorrentAttribute, return that attribute as a String.
-- This is what we need to render the data in HTML tables.


attributeAccessor : Config -> Time.Zone -> Torrent -> TorrentAttribute -> String
attributeAccessor config timezone torrent attribute =
    let
        -- convert 0 speeds to Nothing
        humanByteSpeed =
            \bytes ->
                case bytes of
                    0 ->
                        Nothing

                    r ->
                        Just <| Utils.Filesize.formatWith config.hSpeedSettings r ++ "/s"
    in
    case attribute of
        TorrentStatus ->
            -- TODO
            "NOT SUPPORTED"

        Name ->
            torrent.name

        Size ->
            Utils.Filesize.formatWith config.hSizeSettings torrent.size

        CreationTime ->
            case torrent.creationTime of
                0 ->
                    ""

                r ->
                    View.Utils.DateFormatter.format timezone r

        StartedTime ->
            case torrent.startedTime of
                0 ->
                    ""

                r ->
                    View.Utils.DateFormatter.format timezone r

        FinishedTime ->
            case torrent.finishedTime of
                0 ->
                    ""

                r ->
                    View.Utils.DateFormatter.format timezone r

        DownloadedBytes ->
            Utils.Filesize.formatWith config.hSizeSettings torrent.downloadedBytes

        DownloadRate ->
            humanByteSpeed torrent.downloadRate
                |> Maybe.withDefault ""

        UploadedBytes ->
            Utils.Filesize.formatWith config.hSizeSettings torrent.uploadedBytes

        UploadRate ->
            humanByteSpeed torrent.uploadRate
                |> Maybe.withDefault ""

        Seeders ->
            String.fromInt torrent.seedersConnected
                ++ " ("
                ++ String.fromInt torrent.seedersTotal
                ++ ")"

        SeedersConnected ->
            String.fromInt torrent.seedersConnected

        SeedersTotal ->
            String.fromInt torrent.seedersTotal

        Peers ->
            String.fromInt torrent.peersConnected
                ++ " ("
                ++ String.fromInt torrent.peersTotal
                ++ ")"

        PeersConnected ->
            String.fromInt torrent.peersConnected

        PeersTotal ->
            String.fromInt torrent.peersTotal

        Label ->
            torrent.label

        DonePercent ->
            String.fromFloat torrent.donePercent


textAlignment : TorrentAttribute -> Maybe String
textAlignment attribute =
    case attribute of
        Size ->
            Just "right"

        DownloadedBytes ->
            Just "right"

        DownloadRate ->
            Just "right"

        UploadedBytes ->
            Just "right"

        UploadRate ->
            Just "right"

        Seeders ->
            Just "right"

        SeedersConnected ->
            Just "right"

        SeedersTotal ->
            Just "right"

        Peers ->
            Just "right"

        PeersConnected ->
            Just "right"

        PeersTotal ->
            Just "right"

        _ ->
            Nothing
