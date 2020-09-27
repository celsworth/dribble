module Model.Config exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Model.Table
import Model.Torrent
import Utils.Filesize


type alias Config =
    { refreshDelay : Int
    , sortBy : Model.Torrent.Sort
    , torrentTable : Model.Table.Config
    , visibleTorrentAttributes : List Model.Torrent.Attribute
    , torrentAttributeOrder : List Model.Torrent.Attribute
    , hSizeSettings : Utils.Filesize.Settings
    , hSpeedSettings : Utils.Filesize.Settings
    , timezone : String
    }


setSortBy : Model.Torrent.Sort -> Config -> Config
setSortBy new config =
    { config | sortBy = new }


setTorrentTable : Model.Table.Config -> Config -> Config
setTorrentTable new config =
    { config | torrentTable = new }


setVisibleTorrentAttributes : List Model.Torrent.Attribute -> Config -> Config
setVisibleTorrentAttributes new config =
    { config | visibleTorrentAttributes = new }



-- JSON


default : Config
default =
    { refreshDelay = 5
    , sortBy = Model.Torrent.SortBy Model.Torrent.UploadRate Model.Torrent.Desc
    , torrentTable = Model.Table.defaultConfig
    , visibleTorrentAttributes = defaultTorrentAttributes
    , torrentAttributeOrder = defaultTorrentAttributes
    , hSizeSettings = { units = Utils.Filesize.Base2, decimalPlaces = 2, decimalSeparator = "." }
    , hSpeedSettings = { units = Utils.Filesize.Base10, decimalPlaces = 1, decimalSeparator = "." }
    , timezone = "Europe/London"
    }


defaultTorrentAttributes : List Model.Torrent.Attribute
defaultTorrentAttributes =
    [ Model.Torrent.Status
    , Model.Torrent.Name
    , Model.Torrent.Size
    , Model.Torrent.DonePercent
    , Model.Torrent.CreationTime
    , Model.Torrent.StartedTime
    , Model.Torrent.FinishedTime
    , Model.Torrent.DownloadedBytes
    , Model.Torrent.DownloadRate
    , Model.Torrent.UploadedBytes
    , Model.Torrent.UploadRate
    , Model.Torrent.Seeders

    --, SeedersConnected
    --, SeedersTotal
    , Model.Torrent.Peers

    --, PeersConnected
    --, PeersTotal
    , Model.Torrent.Label
    ]



--- JSON ENCODER


encode : Config -> E.Value
encode config =
    E.object
        [ ( "refreshDelay", E.int config.refreshDelay )
        , ( "sortBy", encodeSortBy config.sortBy )
        , ( "torrentTable", Model.Table.encode config.torrentTable )
        , ( "visibleTorrentAttributes", encodeTorrentAttributeList config.visibleTorrentAttributes )
        , ( "torrentAttributeOrder", encodeTorrentAttributeList config.torrentAttributeOrder )
        , ( "hSizeSettings", Utils.Filesize.encode config.hSizeSettings )
        , ( "hSpeedSettings", Utils.Filesize.encode config.hSpeedSettings )
        , ( "timezone", E.string config.timezone )
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


encodeTorrentAttributeList : List Model.Torrent.Attribute -> E.Value
encodeTorrentAttributeList torrentAttributes =
    E.list encodeTorrentAttribute torrentAttributes


encodeTorrentAttribute : Model.Torrent.Attribute -> E.Value
encodeTorrentAttribute attribute =
    E.string <| Model.Torrent.attributeToKey attribute



{-
   -- for future reference..
   -- => [ {"attribute": "name", "value": 50}, .. ]

   encodeColumnWidthsAsArray : ColumnWidths -> E.Value
   encodeColumnWidthsAsArray columnWidths =
       E.list encodeColumnWidth (Dict.toList columnWidths)


   encodeColumnWidth : ( String, Float ) -> E.Value
   encodeColumnWidth tuple =
       let
           ( attribute, value ) =
               tuple
       in
       E.object
           [ ( "column", E.string attribute )
           , ( "value", E.float value )
           ]

-}
--- JSON DECODERS


decodeOrDefault : D.Value -> Config
decodeOrDefault flags =
    case D.decodeValue decoder flags of
        Ok config ->
            config

        -- not sure if this can actually be reached?
        Err err ->
            let
                _ =
                    Debug.log "JSON Config Decoding Error:" err
            in
            default


decoder : D.Decoder Config
decoder =
    D.succeed Config
        |> optional "refreshDelay" D.int default.refreshDelay
        |> optional "sortBy" sortByDecoder default.sortBy
        |> optional "torrentTable" Model.Table.decoder default.torrentTable
        |> optional "visibleTorrentAttributes"
            torrentAttributeListDecoder
            default.visibleTorrentAttributes
        |> optional "torrentAttributeOrder"
            torrentAttributeListDecoder
            default.torrentAttributeOrder
        |> optional "hSizeSettings"
            Utils.Filesize.decoder
            default.hSizeSettings
        |> optional "hSpeedSettings"
            Utils.Filesize.decoder
            default.hSpeedSettings
        |> optional "timezone" D.string default.timezone


torrentAttributeListDecoder : D.Decoder (List Model.Torrent.Attribute)
torrentAttributeListDecoder =
    D.list torrentAttributeDecoder


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
                        D.fail <| "unknown direction" ++ input
            )


torrentAttributeDecoder : D.Decoder Model.Torrent.Attribute
torrentAttributeDecoder =
    D.string
        |> D.andThen
            (\input ->
                D.succeed <| Model.Torrent.keyToAttribute input
            )
