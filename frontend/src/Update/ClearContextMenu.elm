module Update.ClearContextMenu exposing (update)

import Model exposing (..)


update : Model -> ( Model, Cmd Msg )
update model =
    model
        |> setContextMenu Nothing
        |> noCmd
