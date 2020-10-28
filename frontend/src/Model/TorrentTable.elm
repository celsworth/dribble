module Model.TorrentTable exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E
import List.Extra
import Model.Sort exposing (SortDirection(..))
import Model.Table
import Model.Torrent exposing (Attribute(..))


type alias HeaderContextMenu =
    Column


type alias Column =
    { attribute : Attribute
    , width : Float
    , auto : Bool
    , visible : Bool
    }


type alias Config =
    { tableType : Model.Table.Type
    , layout : Model.Table.Layout
    , columns : List Column
    , sortBy : Model.Torrent.Sort
    }


defaultConfig : Config
defaultConfig =
    { tableType = Model.Table.Torrents
    , layout = Model.Table.Fixed
    , columns = defaultColumns

    -- not actually used, stored in config.sortBy for now
    , sortBy = Model.Torrent.SortBy StartedTime Desc
    }


defaultColumns : List Column
defaultColumns =
    -- used for new torrentTable initialiation only.
    -- changes to this are not picked up in existing configs!
    [ { attribute = Status
      , width = 28
      , auto = False
      , visible = True
      }
    , { attribute = Name
      , width = 300
      , auto = False
      , visible = True
      }
    , { attribute = Size
      , width = 70
      , auto = False
      , visible = True
      }
    , { attribute = FileCount
      , width = 60
      , auto = False
      , visible = False
      }
    , { attribute = DonePercent
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = CreationTime
      , width = 150
      , auto = False
      , visible = False
      }
    , { attribute = StartedTime
      , width = 150
      , auto = False
      , visible = True
      }
    , { attribute = FinishedTime
      , width = 150
      , auto = False
      , visible = False
      }
    , { attribute = DownloadedBytes
      , width = 80
      , auto = False
      , visible = True
      }
    , { attribute = DownloadRate
      , width = 70
      , auto = False
      , visible = True
      }
    , { attribute = UploadedBytes
      , width = 80
      , auto = False
      , visible = True
      }
    , { attribute = UploadRate
      , width = 70
      , auto = False
      , visible = True
      }
    , { attribute = SkippedBytes
      , width = 80
      , auto = False
      , visible = False
      }
    , { attribute = Ratio
      , width = 50
      , auto = False
      , visible = True
      }
    , { attribute = Priority
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = Seeders
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = SeedersConnected
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = SeedersTotal
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = Peers
      , width = 60
      , auto = False
      , visible = True
      }
    , { attribute = PeersConnected
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = PeersTotal
      , width = 30
      , auto = False
      , visible = False
      }
    , { attribute = Label
      , width = 60
      , auto = False
      , visible = True
      }
    ]


defaultColumn : Attribute -> Column
defaultColumn attribute =
    { attribute = attribute
    , width = 50
    , auto = False
    , visible = True
    }


getColumn : Config -> Attribute -> Column
getColumn tableConfig attribute =
    List.Extra.find (\c -> c.attribute == attribute) tableConfig.columns
        |> Maybe.withDefault (defaultColumn attribute)



-- JSON ENCODING


encode : Config -> E.Value
encode config =
    E.object
        [ ( "tableType", Model.Table.encodeTableType config.tableType )
        , ( "layout", Model.Table.encodeLayout config.layout )
        , ( "columns", encodeColumns config.columns )
        , ( "sortBy", Model.Torrent.encodeSortBy config.sortBy )
        ]


encodeColumns : List Column -> E.Value
encodeColumns columns =
    E.list encodeColumn columns


encodeColumn : Column -> E.Value
encodeColumn column =
    E.object
        [ ( "attribute", Model.Torrent.encodeAttribute column.attribute )
        , ( "width", E.float column.width )
        , ( "auto", E.bool column.auto )
        , ( "visible", E.bool column.visible )
        ]



-- JSON DECODER


decoder : D.Decoder Config
decoder =
    D.succeed Config
        |> required "tableType" Model.Table.tableTypeDecoder
        |> required "layout" Model.Table.layoutDecoder
        |> required "columns" columnsDecoder
        |> required "sortBy" Model.Torrent.sortByDecoder


columnsDecoder : D.Decoder (List Column)
columnsDecoder =
    D.list columnDecoder


columnDecoder : D.Decoder Column
columnDecoder =
    D.succeed Column
        |> required "attribute" Model.Torrent.attributeDecoder
        |> required "width" D.float
        |> required "auto" D.bool
        |> required "visible" D.bool
