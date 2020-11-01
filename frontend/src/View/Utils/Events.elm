module View.Utils.Events exposing (onEscape, stopPropagation)

import Html
import Html.Events
import Json.Decode as JD
import Model exposing (Msg(..))


onEscape : Msg -> Html.Attribute Msg
onEscape message =
    Html.Events.on "keyup" <|
        JD.andThen
            (\keyCode ->
                if keyCode == 27 then
                    JD.succeed message

                else
                    JD.fail (String.fromInt keyCode)
            )
            Html.Events.keyCode


stopPropagation : Html.Attribute Msg
stopPropagation =
    Html.Events.stopPropagationOn "mousedown" <| JD.succeed ( NoOp, True )
