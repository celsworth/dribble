module Model.Config exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Model.Table
import Model.Torrent
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
    , sortBy : Model.Torrent.Sort
    , torrentTable : Model.Table.Config
    , humanise : Humanise
    , timezone : String
    , preferences : Model.Window.Config
    , logs : Model.Window.Config
    }


setSortBy : Model.Torrent.Sort -> Config -> Config
setSortBy new config =
    { config | sortBy = new }


setTorrentTable : Model.Table.Config -> Config -> Config
setTorrentTable new config =
    { config | torrentTable = new }


setPreferences : Model.Window.Config -> Config -> Config
setPreferences new config =
    { config | preferences = new }


setLogs : Model.Window.Config -> Config -> Config
setLogs new config =
    { config | logs = new }



-- JSON


default : Config
default =
    { refreshDelay = 5
    , sortBy = Model.Torrent.SortBy Model.Torrent.UploadRate Model.Torrent.Desc
    , torrentTable = Model.TorrentTable.defaultConfig
    , humanise =
        { size = { units = Utils.Filesize.Base2, decimalPlaces = 2, decimalSeparator = "." }
        , speed = { units = Utils.Filesize.Base10, decimalPlaces = 1, decimalSeparator = "." }
        }
    , timezone = "Europe/London"
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
        , ( "humanise", encodeHumanise config.humanise )
        , ( "timezone", E.string config.timezone )
        , ( "preferences", Model.Window.encode config.preferences )
        , ( "logs", Model.Window.encode config.logs )
        ]


encodeSortBy : Model.Torrent.Sort -> E.Value
encodeSortBy sortBy =
    case sortBy of
        Model.Torrent.SortBy column direction ->
            E.object
                [ ( "column", encodeTorrentAttribute column )
                , ( "direction", encodeSortDirection direction )
                ]


encodeSortDirection : Model.Torrent.SortDirection -> E.Value
encodeSortDirection direction =
    case direction of
        Model.Torrent.Asc ->
            E.string "asc"

        Model.Torrent.Desc ->
            E.string "desc"


encodeHumanise : Humanise -> E.Value
encodeHumanise humanise =
    E.object
        [ ( "size", Utils.Filesize.encode humanise.size )
        , ( "speed", Utils.Filesize.encode humanise.speed )
        ]


encodeTorrentAttributeList : List Model.Torrent.Attribute -> E.Value
encodeTorrentAttributeList torrentAttributes =
    E.list encodeTorrentAttribute torrentAttributes


encodeTorrentAttribute : Model.Torrent.Attribute -> E.Value
encodeTorrentAttribute attribute =
    E.string <| Model.Torrent.attributeToKey attribute



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
        |> optional "humanise" humaniseDecoder default.humanise
        |> optional "timezone" D.string default.timezone
        |> optional "preferences" Model.Window.decoder default.preferences
        |> optional "logs" Model.Window.decoder default.logs


sortByDecoder : D.Decoder Model.Torrent.Sort
sortByDecoder =
    D.succeed Model.Torrent.SortBy
        |> required "column" torrentAttributeDecoder
        |> required "direction" sortDirectionDecoder


sortDirectionDecoder : D.Decoder Model.Torrent.SortDirection
sortDirectionDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "asc" ->
                        D.succeed Model.Torrent.Asc

                    "desc" ->
                        D.succeed Model.Torrent.Desc

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


torrentAttributeListDecoder : D.Decoder (List Model.Torrent.Attribute)
torrentAttributeListDecoder =
    D.list torrentAttributeDecoder


torrentAttributeDecoder : D.Decoder Model.Torrent.Attribute
torrentAttributeDecoder =
    D.string
        |> D.andThen
            (\input ->
                case Model.Torrent.keyToAttribute input of
                    Just a ->
                        D.succeed a

                    Nothing ->
                        D.fail <| "unknown torrent key " ++ input
            )
