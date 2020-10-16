module Model.WebsocketData exposing (..)

import Model.File exposing (File)
import Model.Rtorrent
import Model.Torrent exposing (Torrent)
import Model.Traffic exposing (Traffic)



{-
   Simple wrapper around incoming websocket data.

   Subscriptions.elm websocketMessageDecoder returns this,
   and Update.ProcessWebsocketData consumes it.
-}


type Data
    = SystemInfoReceived Model.Rtorrent.Info
    | TorrentsReceived (List Torrent)
    | FilesReceived (List File)
    | TrafficReceived Traffic
    | Error String
