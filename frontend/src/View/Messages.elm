module View.Messages exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Message exposing (Message)
import Time


view : Model -> Html Msg
view model =
    section (sectionAttributes model) [ sectionContents model ]


sectionAttributes : Model -> List (Attribute Msg)
sectionAttributes model =
    List.filterMap identity
        [ Just <| class "messages"
        ]


sectionContents : Model -> Html Msg
sectionContents model =
    messageList model


messageList : Model -> Html Msg
messageList model =
    let
        recentMessages =
            List.filter (isRecent model) model.messages
    in
    ul [] (List.map message recentMessages)


isRecent : Model -> Message -> Bool
isRecent model msg =
    let
        timeDiff =
            Time.posixToMillis model.currentTime - Time.posixToMillis msg.time
    in
    timeDiff < 10 * 1000


message : Message -> Html Msg
message msg =
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
                [ text s ]
