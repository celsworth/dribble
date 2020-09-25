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

        SeedersConnected ->
            "seedersConnected"

        SeedersTotal ->
            "seedersTotal"

        PeersConnected ->
            "peersConnected"

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

        "seedersTotal" ->
            SeedersTotal

        "peersConnected" ->
            PeersConnected

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

        SeedersTotal ->
            "Seeders Total"

        PeersConnected ->
            "Peers Connected"

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


attributeAccessor : Utils.Filesize.Settings -> Time.Zone -> Torrent -> TorrentAttribute -> String
attributeAccessor filesizeSettings timezone torrent attribute =
    let
        speedFilesizeSettings =
            { filesizeSettings | units = Utils.Filesize.Base10, decimalPlaces = 1 }

        -- convert 0 speeds to Nothing
        humanByteSpeed =
            \bytes ->
                case bytes of
                    0 ->
                        Nothing

                    r ->
                        Just <| Utils.Filesize.formatWith speedFilesizeSettings r ++ "/s"
    in
    case attribute of
        TorrentStatus ->
            -- TODO
            "NOT SUPPORTED"

        Name ->
            torrent.name

        Size ->
            Utils.Filesize.formatWith filesizeSettings torrent.size

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
            Utils.Filesize.formatWith filesizeSettings torrent.downloadedBytes

        DownloadRate ->
            humanByteSpeed torrent.downloadRate
                |> Maybe.withDefault ""

        UploadedBytes ->
            Utils.Filesize.formatWith filesizeSettings torrent.uploadedBytes

        UploadRate ->
            humanByteSpeed torrent.uploadRate
                |> Maybe.withDefault ""

        SeedersConnected ->
            String.fromInt torrent.seedersConnected

        SeedersTotal ->
            String.fromInt torrent.seedersTotal

        PeersConnected ->
            String.fromInt torrent.peersConnected

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

        SeedersConnected ->
            Just "right"

        SeedersTotal ->
            Just "right"

        PeersConnected ->
            Just "right"

        _ ->
            Nothing
