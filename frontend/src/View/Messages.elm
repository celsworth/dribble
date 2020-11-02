module View.Messages exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy
import Model exposing (..)
import Model.Message exposing (Message)
import Time
import View.Utils.DateFormatter


view : Model -> Html Msg
view model =
    section [ class "messages" ]
        [ Html.Lazy.lazy3 messageList
            model.messages
            model.timezone
            model.currentTime
        ]


messageList : List Message -> Time.Zone -> Time.Posix -> Html Msg
messageList messages timezone currentTime =
    let
        recentMessages =
            List.filter (isRecent currentTime) messages
    in
    ul [] (List.map (message timezone) recentMessages)


isRecent : Time.Posix -> Message -> Bool
isRecent currentTime msg =
    let
        timeDiff =
            Time.posixToMillis currentTime - Time.posixToMillis msg.time
    in
    timeDiff < 10 * 1000


message : Time.Zone -> Message -> Html Msg
message zone msg =
    let
        kls =
            case msg.severity of
                Model.Message.Info ->
                    "info"

                Model.Message.Warning ->
                    "warning"

                Model.Message.Error ->
                    "error"
    in
    case msg.summary of
        Nothing ->
            text ""

        Just s ->
            li [ class kls ]
                [ span
                    [ class "time" ]
                    [ text <| View.Utils.DateFormatter.format zone msg.time ]
                , text s
                ]
