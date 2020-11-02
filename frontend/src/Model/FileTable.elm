module Model.FileTable exposing (..)

import DnDList
import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E
import List.Extra
import Model.File exposing (Attribute(..))
import Model.Sort exposing (SortDirection(..))
import Model.Table


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
    , sortBy : Model.File.Sort
    }


defaultConfig : Config
defaultConfig =
    { tableType = Model.Table.Files
    , layout = Model.Table.Fixed
    , columns = defaultColumns
    , sortBy = Model.File.SortBy Model.File.Path Asc
    }


defaultColumns : List Column
defaultColumns =
    -- used for new table initialiation only.
    -- changes to this are not picked up in existing configs!
    [ { attribute = Path
      , width = 200
      , auto = False
      , visible = True
      }
    , { attribute = Size
      , width = 70
      , auto = False
      , visible = True
      }
    , { attribute = DonePercent
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
        , ( "sortBy", Model.File.encodeSortBy config.sortBy )
        ]


encodeColumns : List Column -> E.Value
encodeColumns columns =
    E.list encodeColumn columns


encodeColumn : Column -> E.Value
encodeColumn column =
    E.object
        [ ( "attribute", Model.File.encodeAttribute column.attribute )
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
        |> required "sortBy" Model.File.sortByDecoder


columnsDecoder : D.Decoder (List Column)
columnsDecoder =
    D.list columnDecoder


columnDecoder : D.Decoder Column
columnDecoder =
    D.succeed Column
        |> required "attribute" Model.File.attributeDecoder
        |> required "width" D.float
        |> required "auto" D.bool
        |> required "visible" D.bool



-- DND


dndSystem : (Model.Table.Type -> DnDList.Msg -> msg) -> DnDList.System Column msg
dndSystem msg =
    DnDList.create
        { beforeUpdate = \_ _ list -> list
        , movement = DnDList.Vertical
        , listen = DnDList.OnDrag
        , operation = DnDList.Rotate
        }
        (msg Model.Table.Files)
