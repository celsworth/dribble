module Coders.Base exposing (..)

import Coders.Torrent
import Coders.Traffic
import Json.Decode as D
import Json.Encode as E
import Model exposing (..)



-- Generic Decoders


decodeString : String -> Result D.Error DecodedData
decodeString =
    D.decodeString websocketMessageDecoder


decodeStatus : E.Value -> Result D.Error Bool
decodeStatus =
    D.decodeValue websocketStatusDecoder


websocketStatusDecoder : D.Decoder Bool
websocketStatusDecoder =
    D.field "connected" D.bool


websocketMessageDecoder : D.Decoder DecodedData
websocketMessageDecoder =
    D.oneOf
        [ errorDecoder
        , Coders.Torrent.listDecoder
        , Coders.Traffic.decoder
        ]


errorDecoder : D.Decoder DecodedData
errorDecoder =
    D.map Error <|
        D.field "error" D.string



-- Generic Encoders


getTraffic : String
getTraffic =
    E.encode 0 <|
        E.object
            [ ( "save", E.string "trafficRate" )
            , ( "command", getTrafficFields )
            ]


getTrafficFields : E.Value
getTrafficFields =
    E.list identity
        [ E.string "system.multicall"
        , E.list identity
            [ encodeMethodWithParams "system.time" []
            , encodeMethodWithParams "throttle.global_up.total" []
            , encodeMethodWithParams "throttle.global_down.total" []
            ]
        ]


encodeMethodWithParams : String -> List String -> E.Value
encodeMethodWithParams methodName params =
    E.object
        [ ( "methodName", E.string methodName )
        , ( "params", E.list E.string params )
        ]


getFullTorrents : String
getFullTorrents =
    E.encode 0 <|
        E.object
            [ ( "save", E.string "torrentList" )
            , ( "command", getTorrentFields )
            ]


getUpdatedTorrents : String
getUpdatedTorrents =
    E.encode 0 <|
        E.object [ ( "load", E.string "torrentList" ) ]


getTorrentFields : E.Value
getTorrentFields =
    -- TODO: status, ratio
    -- peers, seeds, priority, remaining, save path
    -- ratio group, channel, tracker update time (last_scrape)
    --
    -- probably don't need everything immediately, some can wait..
    --
    -- this order MUST match TorrentDecoder.elm#decoder
    -- and Torrent model definition!
    E.list E.string
        [ "d.multicall2"
        , ""
        , "main"
        , "d.hash="
        , "d.name="
        , "d.size_bytes="
        , "d.creation_date="
        , "d.timestamp.started="
        , "d.timestamp.finished="
        , "d.completed_bytes="
        , "d.down.rate="
        , "d.up.total="
        , "d.up.rate="
        , "d.is_open="
        , "d.is_active="
        , "d.hashing="

        -- seeders (connected)?
        , "d.peers_complete="

        -- seeders (not connected)
        , "cat=\"$t.multicall=d.hash=,t.scrape_complete=,cat={}\""

        -- peers connected ?
        , "d.peers_accounted="

        -- peers (not connected)
        -- cat="$t.multicall=d.hash=,t.scrape_incomplete=,cat={}"
        --
        -- label
        , "d.custom1="
        ]
