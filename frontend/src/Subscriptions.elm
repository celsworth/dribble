module Subscriptions exposing (..)

import Json.Decode as D
import Json.Encode as E
import Model exposing (..)
import Model.TorrentDecoder as TorrentDecoder
import Ports exposing (..)


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver (WebsocketData << decodeString)


decodeString : String -> Result D.Error DecodedData
decodeString =
    D.decodeString websocketMessageDecoder


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


getTorrents : Cmd Msg
getTorrents =
    sendMessage getTorrentsRequest


getTorrentsRequest : String
getTorrentsRequest =
    -- TODO: status, done, ratio
    -- eta, peers, seeds, priority, remaining, save path
    -- ratio group, channel, ratio/day, /week, /month, tracker
    --
    -- downloaded; d.completed_bytes rather than d.down.total ?
    --
    --
    -- probably don't need everything immediately, some can wait..
    E.encode 0 <|
        E.object
            [ ( "command"
              , E.list E.string
                    [ "d.multicall2"
                    , ""
                    , "main"
                    , "d.hash="
                    , "d.name="
                    , "d.size_bytes="
                    , "d.creation_date="
                    , "d.timestamp.started="
                    , "d.timestamp.finished="
                    , "d.up.total="
                    , "d.up.rate="
                    , "d.completed_bytes="
                    , "d.down.rate="

                    -- label
                    , "d.custom1="
                    ]
              )
            ]
