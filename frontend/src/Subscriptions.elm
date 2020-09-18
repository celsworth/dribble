module Subscriptions exposing (..)

import Browser.Events
import Json.Decode as D
import Json.Encode as E
import Model exposing (..)
import Model.TorrentDecoder as TorrentDecoder
import Ports exposing (..)
import Time


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        ticker =
            if model.websocketConnected then
                Just <| Time.every (toFloat model.config.refreshDelay * 1000) RequestUpdatedTorrents

            else
                Nothing

        onMouseMove =
            Browser.Events.onMouseMove <|
                D.map2 MouseMove
                    (D.field "pageX" D.float)
                    (D.field "pageY" D.float)
    in
    Sub.batch <|
        List.filterMap
            identity
        <|
            [ Just <| messageReceiver (WebsocketData << decodeString)
            , Just <| websocketStatusUpdated (WebsocketStatusUpdated << decodeStatus)
            , ticker
            , Just <| onMouseMove
            ]


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
        , TorrentDecoder.listDecoder
        ]


errorDecoder : D.Decoder DecodedData
errorDecoder =
    D.map Error <|
        D.field "error" D.string


getFullTorrents : Cmd Msg
getFullTorrents =
    sendMessage <|
        E.encode 0 <|
            E.object
                [ ( "save", E.string "torrentList" )
                , ( "command", getTorrentFields )
                ]


getUpdatedTorrents : Cmd Msg
getUpdatedTorrents =
    sendMessage <|
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
        , "d.peers_connected="

        -- seeders (connected)?
        -- , "d.peers_complete="
        --
        -- seeders (not connected)
        -- cat="$t.multicall=d.hash=,t.scrape_complete=,cat={}"
        --
        -- peers connected ?
        -- , "d.peers_accounted="
        --
        -- peers (not connected)
        -- cat="$t.multicall=d.hash=,t.scrape_incomplete=,cat={}"
        --
        -- label
        , "d.custom1="
        ]
