module View.Window exposing (..)

import Model.Window


width : Model.Window.Config -> String
width windowConfig =
    String.fromInt windowConfig.width ++ "px"


height : Model.Window.Config -> String
height windowConfig =
    String.fromInt windowConfig.height ++ "px"
