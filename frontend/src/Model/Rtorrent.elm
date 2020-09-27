module Model.Rtorrent exposing (getFullTorrents, getTraffic, getUpdatedTorrents)

import Json.Encode as E
import Model.Traffic exposing (Traffic)


type alias State =
    { traffic : List Traffic
    , version : String
    }



-- WEBSOCKET REQUESTS; TRAFFIC


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
            [ encodeMethodWithParams "system.time_seconds" []
            , encodeMethodWithParams "throttle.global_up.total" []
            , encodeMethodWithParams "throttle.global_down.total" []
            ]
        ]



-- WEBSOCKET; TORRENTS


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