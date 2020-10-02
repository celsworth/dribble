module Model.TorrentTable exposing (Config, RowConfig)

import Model.Table
import Model.Torrent
import Utils.Filesize


type alias Config =
    { sortBy : Model.Torrent.Sort
    , rowConfig : RowConfig
    }



{- configuration settings specific to rendering a *row* of the torrent table

   this has less stuff in it, so we can be choosier about when to re-render
   a row.
-}


type alias RowConfig =
    { visibleTorrentAttributes : List Model.Torrent.Attribute
    , torrentAttributeOrder : List Model.Torrent.Attribute
    , hSizeSettings : Utils.Filesize.Settings
    , hSpeedSettings : Utils.Filesize.Settings
    , torrentTable : Model.Table.Config
    }
