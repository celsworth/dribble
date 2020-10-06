module Model.WebsocketData exposing (..)

import Model.Torrent exposing (Torrent)
import Model.Traffic exposing (Traffic)



{-
   Simple wrapper around incoming websocket data.

   Subscriptions.elm websocketMessageDecoder returns this,
   and Update.ProcessWebsocketData consumes it.
-}


type Data
    = TorrentsReceived (List Torrent)
    | TrafficReceived Traffic
    | Error String
