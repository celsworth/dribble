module Model.Item exposing (..)

import Model.Peer exposing (Peer)



{- item abstraction, ie wrap Peers in something we can pass to a Table

   note that torrents don't appear here because they have a View/TorrentTable
   because they have so much special behaviour.
-}


type Item t
    = Peer Peer
