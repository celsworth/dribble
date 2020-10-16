module Model.TorrentTable exposing (..)

import Model.Attribute exposing (Attribute(..))
import Model.Sort exposing (SortDirection(..))
import Model.Table
import Model.Torrent exposing (Attribute(..))


defaultConfig : Model.Table.Config
defaultConfig =
    { tableType = Model.Table.Torrents
    , layout = Model.Table.Fixed
    , columns = defaultColumns

    -- not actually used, stored in config.sortBy for now
    , sortBy = Model.Attribute.SortBy (TorrentAttribute StartedTime) Desc
    }


defaultColumns : List Model.Table.Column
defaultColumns =
    -- used for new torrentTable initialiation only.
    -- changes to this are not picked up in existing configs!
    [ { attribute = TorrentAttribute Status
      , width = 28
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute Name
      , width = 300
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute Size
      , width = 70
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute DonePercent
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute CreationTime
      , width = 150
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute StartedTime
      , width = 150
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute FinishedTime
      , width = 150
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute DownloadedBytes
      , width = 75
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute DownloadRate
      , width = 85
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute UploadedBytes
      , width = 75
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute UploadRate
      , width = 85
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute SkippedBytes
      , width = 75
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute Ratio
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute Priority
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute Seeders
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute SeedersConnected
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = TorrentAttribute SeedersTotal
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = TorrentAttribute Peers
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = TorrentAttribute PeersConnected
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = TorrentAttribute PeersTotal
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = TorrentAttribute Label
      , width = 60
      , auto = False
      , visible = True
      }
    ]
