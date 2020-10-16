module View.Attribute exposing (attributeTextAlignment)

import Model.Attribute exposing (Attribute(..))
import View.File
import View.Peer
import View.Torrent


attributeTextAlignment : Attribute -> Maybe String
attributeTextAlignment attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            View.Torrent.attributeTextAlignment torrentAttribute

        FileAttribute fileAttribute ->
            View.File.attributeTextAlignment fileAttribute

        PeerAttribute peerAttribute ->
            View.Peer.attributeTextAlignment peerAttribute
