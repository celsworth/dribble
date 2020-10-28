module Model.ContextMenu exposing (..)

import Model.TorrentTable


type alias Position =
    { x : Float
    , y : Float
    }


type ContextMenu
    = TorrentTableHeader Position Model.TorrentTable.HeaderContextMenu
