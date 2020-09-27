module Update.SaveConfig exposing (update)

import Model exposing (..)
import Model.Config
import Ports


update : Model -> ( Model, Cmd Msg )
update model =
    model
        |> addCmd (Model.Config.encode model.config |> Ports.storeConfig)
