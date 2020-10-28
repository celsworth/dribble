module Model.Attribute exposing (..)

import Model.File
import Model.Peer
import Model.Torrent



{- attribute abstraction. Map an Attribute into TorrentAttribute or PeerAttribute etc -}
{- XXX: Sort and SortDirection probably don't belong here -}


type Attribute
    = TorrentAttribute Model.Torrent.Attribute
    | FileAttribute Model.File.Attribute
    | PeerAttribute Model.Peer.Attribute
