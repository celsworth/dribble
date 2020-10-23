module Model.PeerTable exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E
import Model.Peer exposing (Attribute(..))
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
    , sortBy : Model.Peer.Sort
    }


defaultConfig : Config
defaultConfig =
    { tableType = Model.Table.Peers
    , layout = Model.Table.Fixed
    , columns = defaultColumns
    , sortBy = Model.Peer.SortBy Model.Peer.Address Desc
    }


defaultColumns : List Column
defaultColumns =
    -- used for new table initialiation only.
    -- changes to this are not picked up in existing configs!
    [ { attribute = Address
      , width = 50
      , auto = False
      , visible = True
      }
    , { attribute = ClientVersion
      , width = 50
      , auto = False
      , visible = True
      }
    ]



-- JSON ENCODING


encode : Config -> E.Value
encode config =
    E.object
        [ ( "tableType", Model.Table.encodeTableType config.tableType )
        , ( "layout", Model.Table.encodeLayout config.layout )
        , ( "columns", encodeColumns config.columns )
        , ( "sortBy", Model.Peer.encodeSortBy config.sortBy )
        ]


encodeColumns : List Column -> E.Value
encodeColumns columns =
    E.list encodeColumn columns


encodeColumn : Column -> E.Value
encodeColumn column =
    E.object
        [ ( "attribute", Model.Peer.encodeAttribute column.attribute )
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
        |> required "sortBy" Model.Peer.sortByDecoder


columnsDecoder : D.Decoder (List Column)
columnsDecoder =
    D.list columnDecoder


columnDecoder : D.Decoder Column
columnDecoder =
    D.succeed Column
        |> required "attribute" Model.Peer.attributeDecoder
        |> required "width" D.float
        |> required "auto" D.bool
        |> required "visible" D.bool
