module Model.ConfigCoder exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as Pipeline
import Json.Encode as E
import Model exposing (..)


default : Config
default =
    { refreshDelay = 10
    , sortBy = SortBy Name Asc
    , visibleTorrentAttributes = [ Name, Size ]
    }



--- ENODERS


encode : Config -> E.Value
encode config =
    E.object
        [ ( "refreshDelay", E.int config.refreshDelay )
        , ( "sortBy", encodeSortBy config.sortBy )
        , ( "visibleTorrentAttributes", encodeTorrentAttributeList config.visibleTorrentAttributes )
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
    case attribute of
        Name ->
            E.string "name"

        Size ->
            E.string "size"


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
    -- TODO: return a warning message when we use default?
    case D.decodeValue decoder flags of
        Ok config ->
            config

        -- no config stored, or localStorage has invalid JSON?
        _ ->
            default



-- { refreshDelay: 5, sortBy: { column: 'a', direction: 'asc' } }


decoder : D.Decoder Config
decoder =
    D.map3 Config
        (D.field "refreshDelay" D.int)
        (D.field "sortBy" sortByDecoder)
        (D.field "visibleTorrentAttributes" torrentAttributeListDecoder)


torrentAttributeListDecoder : D.Decoder (List TorrentAttribute)
torrentAttributeListDecoder =
    D.list torrentAttributeDecoder


sortByDecoder : D.Decoder Sort
sortByDecoder =
    D.map2 SortBy
        (D.field "column" torrentAttributeDecoder)
        (D.field "direction" D.string |> D.andThen sortDirectionDecoder)


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

                    _ ->
                        D.fail <| "unknown attribute" ++ input
            )


sortDirectionDecoder : String -> D.Decoder SortDirection
sortDirectionDecoder input =
    case input of
        "asc" ->
            D.succeed Asc

        "desc" ->
            D.succeed Desc

        _ ->
            D.fail <| "unknown direction" ++ input
