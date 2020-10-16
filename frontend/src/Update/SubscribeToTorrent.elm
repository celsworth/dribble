module Update.SubscribeToTorrent exposing (update)

import Model exposing (..)
import Ports


update : Model -> ( Model, Cmd Msg )
update model =
    model
        |> addCmd (Ports.getFiles model)
