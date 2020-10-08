module Model.Config exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Model.Attribute
import Model.Table
import Model.Torrent
import Model.TorrentFilter
import Model.TorrentTable
import Model.Window
import Utils.Filesize


type ConfigWithResult
    = DecodeOk Config
    | DecodeError String Config


type alias Humanise =
    { size : Utils.Filesize.Settings
    , speed : Utils.Filesize.Settings
    }


type alias Config =
    { refreshDelay : Int
    , sortBy : Model.Attribute.Sort
    , torrentTable : Model.Table.Config
    , filter : Model.TorrentFilter.Config
    , humanise : Humanise
    , preferences : Model.Window.Config
    , logs : Model.Window.Config
    }


setSortBy : Model.Attribute.Sort -> Config -> Config
setSortBy new config =
    { config | sortBy = new }


setTorrentTable : Model.Table.Config -> Config -> Config
setTorrentTable new config =
    { config | torrentTable = new }


setFilter : Model.TorrentFilter.Config -> Config -> Config
setFilter new config =
    { config | filter = new }


setPreferences : Model.Window.Config -> Config -> Config
setPreferences new config =
    { config | preferences = new }


setLogs : Model.Window.Config -> Config -> Config
setLogs new config =
    { config | logs = new }



-- DEFAULT


default : Config
default =
    { refreshDelay = 5
    , sortBy = Model.Attribute.SortBy (Model.Attribute.TorrentAttribute Model.Torrent.UploadRate) Model.Attribute.Desc
    , torrentTable = Model.TorrentTable.defaultConfig
    , filter = Model.TorrentFilter.default
    , humanise =
        { size = { units = Utils.Filesize.Base2, decimalPlaces = 2, decimalSeparator = "." }
        , speed = { units = Utils.Filesize.Base10, decimalPlaces = 1, decimalSeparator = "." }
        }
    , preferences = { visible = False, width = 600, height = 400 }
    , logs = { visible = False, width = 800, height = 400 }
    }



--- JSON ENCODER


encode : Config -> E.Value
encode config =
    E.object
        [ ( "refreshDelay", E.int config.refreshDelay )
        , ( "sortBy", encodeSortBy config.sortBy )
        , ( "torrentTable", Model.Table.encode config.torrentTable )
        , ( "filter", Model.TorrentFilter.encode config.filter )
        , ( "humanise", encodeHumanise config.humanise )
        , ( "preferences", Model.Window.encode config.preferences )
        , ( "logs", Model.Window.encode config.logs )
        ]


encodeSortBy : Model.Attribute.Sort -> E.Value
encodeSortBy sortBy =
    case sortBy of
        Model.Attribute.SortBy column direction ->
            E.object
                [ ( "column", encodeTorrentAttribute column )
                , ( "direction", encodeSortDirection direction )
                ]


encodeSortDirection : Model.Attribute.SortDirection -> E.Value
encodeSortDirection direction =
    case direction of
        Model.Attribute.Asc ->
            E.string "asc"

        Model.Attribute.Desc ->
            E.string "desc"


encodeHumanise : Humanise -> E.Value
encodeHumanise humanise =
    E.object
        [ ( "size", Utils.Filesize.encode humanise.size )
        , ( "speed", Utils.Filesize.encode humanise.speed )
        ]


encodeTorrentAttributeList : List Model.Attribute.Attribute -> E.Value
encodeTorrentAttributeList torrentAttributes =
    E.list encodeTorrentAttribute torrentAttributes


encodeTorrentAttribute : Model.Attribute.Attribute -> E.Value
encodeTorrentAttribute attribute =
    E.string <| Model.Torrent.attributeToKey (Model.Attribute.unwrap attribute)



--- JSON DECODERS


decodeOrDefault : D.Value -> ConfigWithResult
decodeOrDefault flags =
    case D.decodeValue decoder flags of
        Ok config ->
            DecodeOk config

        -- reached if anything below calls .fail
        Err err ->
            DecodeError (D.errorToString err) default


decoder : D.Decoder Config
decoder =
    D.succeed Config
        |> optional "refreshDelay" D.int default.refreshDelay
        |> optional "sortBy" sortByDecoder default.sortBy
        |> optional "torrentTable" Model.Table.decoder default.torrentTable
        |> optional "filter" Model.TorrentFilter.decoder default.filter
        |> optional "humanise" humaniseDecoder default.humanise
        |> optional "preferences" Model.Window.decoder default.preferences
        |> optional "logs" Model.Window.decoder default.logs


sortByDecoder : D.Decoder Model.Attribute.Sort
sortByDecoder =
    D.succeed Model.Attribute.SortBy
        |> required "column" torrentAttributeDecoder
        |> required "direction" sortDirectionDecoder


sortDirectionDecoder : D.Decoder Model.Attribute.SortDirection
sortDirectionDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "asc" ->
                        D.succeed Model.Attribute.Asc

                    "desc" ->
                        D.succeed Model.Attribute.Desc

                    _ ->
                        D.fail <| "unknown direction " ++ input
            )


humaniseDecoder : D.Decoder Humanise
humaniseDecoder =
    D.succeed Humanise
        |> optional "size"
            Utils.Filesize.decoder
            default.humanise.size
        |> optional "speed"
            Utils.Filesize.decoder
            default.humanise.speed


torrentAttributeListDecoder : D.Decoder (List Model.Attribute.Attribute)
torrentAttributeListDecoder =
    D.list torrentAttributeDecoder


torrentAttributeDecoder : D.Decoder Model.Attribute.Attribute
torrentAttributeDecoder =
    D.string
        |> D.andThen
            (\input ->
                case Model.Torrent.keyToAttribute input of
                    Just a ->
                        D.succeed <| Model.Attribute.TorrentAttribute a

                    Nothing ->
                        D.fail <| "unknown torrent key " ++ input
            )
