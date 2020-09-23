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
            ""

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

        Label ->
            "Label"

        DonePercent ->
            "Done"

        _ ->
            "UNHANDLED ATTRIBUTE"


attributeToTableHeaderString : TorrentAttribute -> String
attributeToTableHeaderString attribute =
    case attribute of
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
    case attribute of
        TorrentStatus ->
            -- TODO
            "NOT SUPPORTED"

        Name ->
            torrent.name

        Size ->
            humanBytes filesizeSettings torrent.size

        CreationTime ->
            case torrent.creationTime of
                0 ->
                    ""

                r ->
                    View.Utils.DateFormatter.format timezone r

        StartedTime ->
            View.Utils.DateFormatter.format timezone torrent.startedTime

        FinishedTime ->
            case torrent.finishedTime of
                0 ->
                    ""

                r ->
                    View.Utils.DateFormatter.format timezone r

        DownloadedBytes ->
            humanBytes filesizeSettings torrent.downloadedBytes

        DownloadRate ->
            humanByteSpeed filesizeSettings torrent.downloadRate

        UploadedBytes ->
            humanBytes filesizeSettings torrent.uploadedBytes

        UploadRate ->
            humanByteSpeed filesizeSettings torrent.uploadRate

        PeersConnected ->
            String.fromInt torrent.peersConnected

        Label ->
            torrent.label

        DonePercent ->
            String.fromFloat torrent.donePercent


humanBytes : Utils.Filesize.Settings -> Int -> String
humanBytes settings num =
    Utils.Filesize.formatWith settings num


humanByteSpeed : Utils.Filesize.Settings -> Int -> String
humanByteSpeed settings num =
    -- could return a Maybe? As we don't want to show anything for zero speed
    case num of
        0 ->
            ""

        r ->
            humanBytes settings r ++ "/s"


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

        PeersConnected ->
            Just "right"

        _ ->
            Nothing
