module Model.Rtorrent exposing
    ( Info
    , decoder
    , getFiles
    , getSystemInfo
    , getTorrents
    , getTraffic
    )

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
            , ( "interval", E.int 10 )
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


getTorrentFields : E.Value
getTorrentFields =
    -- TODO:
    -- save path, ratio group, channel, tracker update time (last_scrape)
    --
    -- this order MUST match Model/Torrent.elm #decoder and Torrent model definition!
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
        , "d.skip.total="
        , "d.is_open="
        , "d.is_active="
        , "d.hashing="
        , "d.message="
        , "d.priority="

        -- seeders (connected)
        , "d.peers_complete="

        -- seeders (not connected)
        , "cat=\"$t.multicall=d.hash=,t.scrape_complete=,cat={}\""

        -- peers (connected)
        , "d.peers_accounted="

        -- peers (not connected)
        , "cat=\"$t.multicall=d.hash=,t.scrape_incomplete=,cat={}\""

        -- label
        , "d.custom1="
        ]



-- WEBSOCKET; FILES


getFiles : String -> Config -> String
getFiles selectedTorrentHash config =
    E.encode 0 <|
        E.object
            [ ( "subscribe", E.string "fileList" )
            , ( "diff", E.bool True )
            , ( "interval", E.int config.refreshDelay )
            , ( "command", getFileFields selectedTorrentHash )
            ]


getFileFields : String -> E.Value
getFileFields selectedTorrentHash =
    -- this order MUST match Model/File.elm #decoder and File model definition!
    E.list E.string
        [ "f.multicall"
        , selectedTorrentHash
        , ""
        , "f.path="
        , "f.size_bytes="
        , "f.size_chunks="
        , "f.completed_chunks="
        , "f.priority="
        ]



-- WEBSOCKET; PEERS


getPeerFields : E.Value
getPeerFields =
    -- this order MUST match Model/Peer.elm #decoder and Peer model definition!
    E.list E.string
        [ "p.multicall"
        , ""
        , ""
        , "p.address="
        , "p.client_version="
        , "p.completed_percent="

        -- peer_rate / peer_total
        -- down_rate or down_total ?
        -- up_rate or up_total ?
        -- is_encrypted
        -- is_incoming
        -- is_obsfucated
        -- is_preferred
        -- is_unwanted
        -- is_snubbed
        ]


encodeMethodWithParams : String -> List String -> E.Value
encodeMethodWithParams methodName params =
    E.object
        [ ( "methodName", E.string methodName )
        , ( "params", E.list E.string params )
        ]
