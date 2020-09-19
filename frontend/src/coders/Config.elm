module Coders.Config exposing (..)

import Coders.FilesizeSettings
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
    , filesizeSettings = Utils.Filesize.defaultSettings
    }


defaultTorrentAttributes : List TorrentAttribute
defaultTorrentAttributes =
    [ Name
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



--- ENODERS


encode : Config -> E.Value
encode config =
    E.object
        [ ( "refreshDelay", E.int config.refreshDelay )
        , ( "sortBy", encodeSortBy config.sortBy )
        , ( "visibleTorrentAttributes", encodeTorrentAttributeList config.visibleTorrentAttributes )
        , ( "torrentAttributeOrder", encodeTorrentAttributeList config.torrentAttributeOrder )
        , ( "filesizeSettings", Coders.FilesizeSettings.encode config.filesizeSettings )
        ]


encodeSortBy : Sort -> E.Value
encodeSortBy sortBy =
    case sortBy of
        SortBy column direction ->
            E.object
                [ ( "column", encodeTorrentAttribute column )
                , ( "direction", encodeSortDirection direction )
                ]


encodeTorrentAttributeList : List TorrentAttribute -> E.Value
encodeTorrentAttributeList torrentAttributes =
    E.list encodeTorrentAttribute torrentAttributes


encodeTorrentAttribute : TorrentAttribute -> E.Value
encodeTorrentAttribute attribute =
    E.string <| Model.Utils.TorrentAttribute.attributeToKey attribute


encodeSortDirection : SortDirection -> E.Value
encodeSortDirection direction =
    case direction of
        Asc ->
            E.string "asc"

        Desc ->
            E.string "desc"



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
        |> optional "filesizeSettings"
            Coders.FilesizeSettings.decoder
            default.filesizeSettings


torrentAttributeListDecoder : D.Decoder (List TorrentAttribute)
torrentAttributeListDecoder =
    D.list torrentAttributeDecoder


sortByDecoder : D.Decoder Sort
sortByDecoder =
    D.succeed SortBy
        |> required "column" torrentAttributeDecoder
        |> required "direction" sortDirectionDecoder


torrentAttributeDecoder : D.Decoder TorrentAttribute
torrentAttributeDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "name" ->
                        D.succeed Name

                    "size" ->
                        D.succeed Size

                    "creationTime" ->
                        D.succeed CreationTime

                    "startedTime" ->
                        D.succeed StartedTime

                    "finishedTime" ->
                        D.succeed FinishedTime

                    "downloadedBytes" ->
                        D.succeed DownloadedBytes

                    "downloadRate" ->
                        D.succeed DownloadRate

                    "uploadedBytes" ->
                        D.succeed UploadedBytes

                    "uploadRate" ->
                        D.succeed UploadRate

                    "peersConnected" ->
                        D.succeed PeersConnected

                    "label" ->
                        D.succeed Label

                    _ ->
                        D.fail <| "unknown attribute" ++ input
            )


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
