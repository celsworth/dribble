module Update.SetCurrentTime exposing (update)

import Model exposing (..)
import Model.Message exposing (Message)
import Time


update : Time.Posix -> Model -> ( Model, Cmd Msg )
update time model =
    model
        |> setCurrentTime time
        |> addCmd Cmd.none
