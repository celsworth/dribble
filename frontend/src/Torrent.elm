module Torrent exposing (..)

import Dict exposing (Dict)
import Filesize
import Model exposing (..)
import View.Utils.DateFormatter



--- unused but kept for reference for a while


attributeStringToTorrentAttribute : String -> TorrentAttribute -> TorrentAttribute
attributeStringToTorrentAttribute name default =
    case name of
        "name" ->
            Name

        "size" ->
            Size

        _ ->
            default



-- Given a Torrent and TorrentAttribute, return that attribute as a String.
-- This is what we need to render the data in HTML tables.


attributeAccessor : Filesize.Settings -> Torrent -> TorrentAttribute -> String
attributeAccessor filesizeSettings torrent attribute =
    case attribute of
        Name ->
            torrent.name

        Size ->
            Filesize.formatWith filesizeSettings torrent.size

        CreationTime ->
            View.Utils.DateFormatter.format torrent.creationTime

        StartedTime ->
            View.Utils.DateFormatter.format torrent.startedTime

        FinishedTime ->
            View.Utils.DateFormatter.format torrent.finishedTime

        UploadedBytes ->
            Filesize.formatWith filesizeSettings torrent.uploadedBytes

        UploadRate ->
            Filesize.formatWith filesizeSettings torrent.uploadRate

        DownloadedBytes ->
            Filesize.formatWith filesizeSettings torrent.downloadedBytes

        DownloadRate ->
            Filesize.formatWith filesizeSettings torrent.downloadRate

        Label ->
            torrent.label
