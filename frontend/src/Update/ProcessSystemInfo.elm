module Update.ProcessSystemInfo exposing (update)

import Model exposing (..)
import Model.Rtorrent


update : Model.Rtorrent.Info -> Model -> ( Model, Cmd Msg )
update info model =
    model
        |> setRtorrentSystemInfo info
        |> noCmd
