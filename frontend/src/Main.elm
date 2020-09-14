module Main exposing (..)

import Browser
import Init
import Json.Decode
import Model exposing (..)
import Subscriptions
import Update
import View


type alias Msg =
    Model.Msg


main : Program Json.Decode.Value Model Msg
main =
    Browser.element
        { init = Init.init
        , view = View.view
        , update = Update.update
        , subscriptions = Subscriptions.subscriptions
        }
