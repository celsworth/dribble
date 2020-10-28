module View.Utils.Events exposing (onEscape)

import Html
import Html.Events
import Json.Decode as JD


onEscape : msg -> Html.Attribute msg
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
