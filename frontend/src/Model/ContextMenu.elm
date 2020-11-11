module Model.ContextMenu exposing (..)

import Model.FileTable
import Model.TorrentTable
import Utils.Mouse as Mouse


type For
    = TorrentTableColumn Model.TorrentTable.Column
    | FileTableColumn Model.FileTable.Column


type alias ContextMenu =
    { for : For
    , position : Mouse.Position
    }
