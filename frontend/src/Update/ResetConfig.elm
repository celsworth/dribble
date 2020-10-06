module Update.ResetConfig exposing (update)

import Model exposing (..)
import Model.Config


update : Model -> ( Model, Cmd Msg )
update model =
    model |> setConfig Model.Config.default |> noCmd
