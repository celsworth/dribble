module Model.Rtorrent exposing (Info, decoder, getSystemInfo, getTorrents, getTraffic, getUpdatedTorrents)

import Json.Decode as D
import Json.Decode.Pipeline exposing (custom)
import Json.Encode as E
import Model.Config exposing (Config)


type alias Info =
    { hostname : String
    , listenPort : Int
    , systemVersion : String
    , libraryVersion : String
    }



-- JSON DECODER


decoder : D.Decoder Info
decoder =
    D.succeed Info
        |> custom (D.index 0 stringFromArrayDecoder)
        |> custom (D.index 1 intFromArrayDecoder)
        |> custom (D.index 2 stringFromArrayDecoder)
        |> custom (D.index 3 stringFromArrayDecoder)


intFromArrayDecoder : D.Decoder Int
intFromArrayDecoder =
    D.index 0 D.int


stringFromArrayDecoder : D.Decoder String
stringFromArrayDecoder =
    D.index 0 D.string



-- WEBSOCKET; SYSTEM INFO


getSystemInfo : String
getSystemInfo =
    E.encode 0 <|
        E.object
            [ ( "name", E.string "systemInfo" )
            , ( "command", getSystemInfoFields )
            ]


getSystemInfoFields : E.Value
getSystemInfoFields =
    E.list identity
        [ E.string "system.multicall"
        , E.list identity
            [ encodeMethodWithParams "system.hostname" []
            , encodeMethodWithParams "network.listen.port" []
            , encodeMethodWithParams "system.client_version" []
            , encodeMethodWithParams "system.library_version" []
            ]
        ]



-- WEBSOCKET; TRAFFIC


getTraffic : String
getTraffic =
    E.encode 0 <|
        E.object
            [ ( "subscribe", E.string "trafficRate" )
            , ( "diff", E.bool False )
            , ( "interval", E.int 5 )
            , ( "command", getTrafficFields )
            ]


getTrafficFields : E.Value
getTrafficFields =
    E.list identity
        [ E.string "system.multicall"
        , E.list identity
            [ encodeMethodWithParams "system.time_seconds" []
            , encodeMethodWithParams "throttle.global_up.total" []
            , encodeMethodWithParams "throttle.global_down.total" []
            ]
        ]



-- WEBSOCKET; TORRENTS


getTorrents : Config -> String
getTorrents config =
    E.encode 0 <|
        E.object
            [ ( "subscribe", E.string "torrentList" )
            , ( "diff", E.bool True )
            , ( "interval", E.int config.refreshDelay )
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
    -- this order MUST match Model/Torrent.elm #decoder
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
        , "d.message="
        , "d.priority="

        -- seeders (connected)?
        , "d.peers_complete="

        -- seeders (not connected)
        , "cat=\"$t.multicall=d.hash=,t.scrape_complete=,cat={}\""

        -- peers connected ?
        , "d.peers_accounted="

        -- peers (not connected)
        , "cat=\"$t.multicall=d.hash=,t.scrape_incomplete=,cat={}\""

        -- label
        , "d.custom1="
        ]


encodeMethodWithParams : String -> List String -> E.Value
encodeMethodWithParams methodName params =
    E.object
        [ ( "methodName", E.string methodName )
        , ( "params", E.list E.string params )
        ]
