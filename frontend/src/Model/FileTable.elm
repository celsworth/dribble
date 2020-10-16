module Model.FileTable exposing (..)

import Model.Attribute exposing (Attribute(..))
import Model.File exposing (Attribute(..))
import Model.Sort exposing (SortDirection(..))
import Model.Table



-- t is probably Model.Table.Column ?


type alias Column t =
    { t
        | attribute : Attribute
    }


type alias Config t =
    { t
        | columns : List (Column t)
        , sortBy : Attribute
    }


defaultConfig : Model.Table.Config
defaultConfig =
    { tableType = Model.Table.Files
    , layout = Model.Table.Fixed
    , columns = defaultColumns
    , sortBy = Model.Attribute.SortBy (FileAttribute Path) Asc
    }


defaultColumns : List Model.Table.Column
defaultColumns =
    -- used for new table initialiation only.
    -- changes to this are not picked up in existing configs!
    [ { attribute = FileAttribute Path
      , width = 200
      , auto = False
      , visible = True
      }
    , { attribute = FileAttribute Size
      , width = 70
      , auto = False
      , visible = True
      }
    , { attribute = FileAttribute DonePercent
      , width = 60
      , auto = False
      , visible = True
      }
    ]
