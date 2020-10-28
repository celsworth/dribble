module Model.ContextMenu exposing (..)

import Model.FileTable
import Model.TorrentTable


type For
    = TorrentsTableColumn Model.TorrentTable.Column
    | FilesTableColumn Model.FileTable.Column


type alias Position =
    { x : Float
    , y : Float
    }


type alias ContextMenu =
    { for : For
    , position : Position
    }
