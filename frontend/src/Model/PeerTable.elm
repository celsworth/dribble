module Model.PeerTable exposing (..)

import Model.Attribute exposing (Attribute(..))
import Model.Peer exposing (Attribute(..))
import Model.Sort exposing (SortDirection(..))
import Model.Table


defaultConfig : Model.Table.Config
defaultConfig =
    { tableType = Model.Table.Peers
    , layout = Model.Table.Fixed
    , columns = defaultColumns
    , sortBy = Model.Attribute.SortBy (PeerAttribute Status) Desc
    }


defaultColumns : List Model.Table.Column
defaultColumns =
    -- used for new torrentTable initialiation only.
    -- changes to this are not picked up in existing configs!
    [ { attribute = PeerAttribute Status
      , width = 50
      , auto = False
      , visible = True
      }
    , { attribute = PeerAttribute Address
      , width = 50
      , auto = False
      , visible = True
      }
    ]
