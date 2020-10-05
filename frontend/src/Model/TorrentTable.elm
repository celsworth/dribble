module Model.TorrentTable exposing (..)

import Model.Table
import Model.Torrent


defaultConfig : Model.Table.Config
defaultConfig =
    { tableType = Model.Table.Torrents
    , layout = Model.Table.Fixed
    , columns = defaultColumns
    }


defaultColumns : List Model.Table.Column
defaultColumns =
    -- used for new torrentTable initialiation only.
    -- changes to this are not picked up in existing configs!
    [ { attribute = Model.Table.TorrentAttribute Model.Torrent.Status
      , width = 28
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.Name
      , width = 300
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.Size
      , width = 70
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.DonePercent
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.CreationTime
      , width = 146
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.StartedTime
      , width = 146
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.FinishedTime
      , width = 146
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.DownloadedBytes
      , width = 75
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.DownloadRate
      , width = 85
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.UploadedBytes
      , width = 75
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.UploadRate
      , width = 85
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.Seeders
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.SeedersConnected
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.SeedersTotal
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.Peers
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.PeersConnected
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.PeersTotal
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = Model.Table.TorrentAttribute Model.Torrent.Label
      , width = 60
      , auto = False
      , visible = True
      }
    ]
