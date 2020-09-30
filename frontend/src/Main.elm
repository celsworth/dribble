module Main exposing (main)

import Browser
import Init exposing (Flags)
import Model exposing (Model, Msg)
import Subscriptions
import Update
import View


main : Program Flags Model Msg
main =
    Browser.element
        { init = Init.init
        , update = Update.update
        , view = View.view
        , subscriptions = Subscriptions.subscriptions
        }
