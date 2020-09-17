module View.Utils.TorrentAttributeMethods exposing (..)

import Filesize
import Model exposing (..)
import View.Utils.DateFormatter



-- return a human readable version of a TorrentAttribute definition.
-- this is used in HTML when there is no other specific method available
-- (eg, we have one for table headers which has shorter strings for some)


attributeToString : TorrentAttribute -> String
attributeToString attribute =
    case attribute of
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


attributeAccessor : Filesize.Settings -> Torrent -> TorrentAttribute -> String
attributeAccessor filesizeSettings torrent attribute =
    case attribute of
        Name ->
            torrent.name

        Size ->
            humanBytes filesizeSettings torrent.size

        CreationTime ->
            case torrent.creationTime of
                0 ->
                    ""

                r ->
                    View.Utils.DateFormatter.format r

        StartedTime ->
            View.Utils.DateFormatter.format torrent.startedTime

        FinishedTime ->
            case torrent.finishedTime of
                0 ->
                    ""

                r ->
                    View.Utils.DateFormatter.format r

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


humanBytes : Filesize.Settings -> Int -> String
humanBytes settings num =
    Filesize.formatWith settings num


humanByteSpeed : Filesize.Settings -> Int -> String
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
