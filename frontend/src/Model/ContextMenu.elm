module Model.ContextMenu exposing (..)

import Model.FileTable
import Model.TorrentTable


type For
    = TorrentTableColumn Model.TorrentTable.Column
    | FileTableColumn Model.FileTable.Column


type alias Position =
    { x : Float
    , y : Float
    }


type alias ContextMenu =
    { for : For
    , position : Position
    }
