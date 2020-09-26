module Update.SaveConfig exposing (update)

import Coders.Config
import Model exposing (..)
import Ports


update : Model -> ( Model, Cmd Msg )
update model =
    model
        |> addCmd (Coders.Config.encode model.config |> Ports.storeConfig)
