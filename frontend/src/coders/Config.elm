module Coders.Config exposing (..)

import Coders.FilesizeSettings
import Dict
import Json.Decode as D
import Json.Decode.Pipeline as Pipeline exposing (optional, required)
import Json.Encode as E
import Model exposing (..)
import Model.Utils.TorrentAttribute
import Utils.Filesize


default : Config
default =
    { refreshDelay = 5
    , sortBy = SortBy UploadRate Desc
    , visibleTorrentAttributes = defaultTorrentAttributes
    , torrentAttributeOrder = defaultTorrentAttributes
    , columnWidths = defaultColumnWidths
    , filesizeSettings = Utils.Filesize.defaultSettings
    , timezone = "Europe/London"
    }


defaultTorrentAttributes : List TorrentAttribute
defaultTorrentAttributes =
    [ TorrentStatus
    , Name
    , Size
    , DonePercent
    , CreationTime
    , StartedTime
    , FinishedTime
    , DownloadedBytes
    , DownloadRate
    , UploadedBytes
    , UploadRate
    , Label
    ]


defaultColumnWidths : ColumnWidths
defaultColumnWidths =
    Dict.fromList <|
        List.map defaultColumnWidth defaultTorrentAttributes


defaultColumnWidth : TorrentAttribute -> ( String, ColumnWidth )
defaultColumnWidth attribute =
    -- naive, TODO: set some better defaults per column
    ( Model.Utils.TorrentAttribute.attributeToKey
        attribute
    , { px = 50, auto = False }
    )



--- ENODERS


encode : Config -> E.Value
encode config =
    E.object
        [ ( "refreshDelay", E.int config.refreshDelay )
        , ( "sortBy", encodeSortBy config.sortBy )
        , ( "visibleTorrentAttributes", encodeTorrentAttributeList config.visibleTorrentAttributes )
        , ( "torrentAttributeOrder", encodeTorrentAttributeList config.torrentAttributeOrder )
        , ( "columnWidths", encodeColumnWidths config.columnWidths )
        , ( "filesizeSettings", Coders.FilesizeSettings.encode config.filesizeSettings )
        , ( "timezone", E.string config.timezone )
        ]


encodeSortBy : Sort -> E.Value
encodeSortBy sortBy =
    case sortBy of
        SortBy column direction ->
            E.object
                [ ( "column", encodeTorrentAttribute column )
                , ( "direction", encodeSortDirection direction )
                ]


encodeSortDirection : SortDirection -> E.Value
encodeSortDirection direction =
    case direction of
        Asc ->
            E.string "asc"

        Desc ->
            E.string "desc"


encodeTorrentAttributeList : List TorrentAttribute -> E.Value
encodeTorrentAttributeList torrentAttributes =
    E.list encodeTorrentAttribute torrentAttributes


encodeTorrentAttribute : TorrentAttribute -> E.Value
encodeTorrentAttribute attribute =
    E.string <| Model.Utils.TorrentAttribute.attributeToKey attribute


encodeColumnWidths : ColumnWidths -> E.Value
encodeColumnWidths columnWidths =
    Dict.toList columnWidths
        |> List.map (\( k, v ) -> ( k, encodeColumnWidth v ))
        |> E.object


encodeColumnWidth : ColumnWidth -> E.Value
encodeColumnWidth columnWidth =
    E.object
        [ ( "px", E.float columnWidth.px )
        , ( "auto", E.bool columnWidth.auto )
        ]



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
--- DECODERS


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
        |> optional "visibleTorrentAttributes"
            torrentAttributeListDecoder
            default.visibleTorrentAttributes
        |> optional "torrentAttributeOrder"
            torrentAttributeListDecoder
            default.torrentAttributeOrder
        |> optional "columnWidths"
            columnWidthsDecoder
            default.columnWidths
        |> optional "filesizeSettings"
            Coders.FilesizeSettings.decoder
            default.filesizeSettings
        |> optional "timezone" D.string default.timezone


torrentAttributeListDecoder : D.Decoder (List TorrentAttribute)
torrentAttributeListDecoder =
    D.list torrentAttributeDecoder


sortByDecoder : D.Decoder Sort
sortByDecoder =
    D.succeed SortBy
        |> required "column" torrentAttributeDecoder
        |> required "direction" sortDirectionDecoder


sortDirectionDecoder : D.Decoder SortDirection
sortDirectionDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "asc" ->
                        D.succeed Asc

                    "desc" ->
                        D.succeed Desc

                    _ ->
                        D.fail <| "unknown direction" ++ input
            )


torrentAttributeDecoder : D.Decoder TorrentAttribute
torrentAttributeDecoder =
    D.string
        |> D.andThen
            (\input ->
                D.succeed <| Model.Utils.TorrentAttribute.keyToAttribute input
            )


columnWidthsDecoder : D.Decoder ColumnWidths
columnWidthsDecoder =
    D.dict columnWidthDecoder


columnWidthDecoder : D.Decoder ColumnWidth
columnWidthDecoder =
    D.succeed ColumnWidth
        |> required "px" D.float
        |> required "auto" D.bool
