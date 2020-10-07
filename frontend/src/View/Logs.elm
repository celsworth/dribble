module View.Logs exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy
import Model exposing (..)
import Model.Message exposing (Message)
import Model.Window
import Time
import View.Utils.DateFormatter
import View.Window


view : Model -> Html Msg
view model =
    section
        (sectionAttributes model.config.logs)
        [ Html.Lazy.lazy2 sectionContents model.timezone model.messages ]


sectionAttributes : Model.Window.Config -> List (Attribute Msg)
sectionAttributes windowConfig =
    List.filterMap identity
        [ Just <| class "logs window"
        , Just <| id "logs"
        , Just <| style "width" (View.Window.width windowConfig)
        , Just <| style "height" (View.Window.height windowConfig)
        , displayClass windowConfig
        ]


displayClass : Model.Window.Config -> Maybe (Attribute Msg)
displayClass windowConfig =
    if windowConfig.visible then
        Just <| class "visible"

    else
        Nothing


sectionContents : Time.Zone -> List Message -> Html Msg
sectionContents timezone messages =
    div []
        [ div [ class "titlebar" ]
            [ i
                [ class "close-icon fas fa-times-circle"
                , onClick ToggleLogsVisible
                ]
                []
            , strong [] [ text <| "Logs" ]
            ]
        , messageList timezone messages
        ]


messageList : Time.Zone -> List Message -> Html Msg
messageList timezone messages =
    ol [] (List.map (messageItem timezone) messages)


messageItem : Time.Zone -> Message -> Html Msg
messageItem timezone msg =
    li [ class (messageItemClass msg.severity) ]
        [ messageTime timezone msg, messageContent msg ]


messageItemClass : Model.Message.Severity -> String
messageItemClass severity =
    case severity of
        Model.Message.Info ->
            "info"

        Model.Message.Warning ->
            "warning"

        Model.Message.Error ->
            "error"


messageTime : Time.Zone -> Message -> Html Msg
messageTime timezone msg =
    strong [ class "time" ] [ text <| formattedTime timezone msg.time ]


messageContent : Message -> Html Msg
messageContent msg =
    div [ class "content" ] <|
        List.filterMap identity
            [ Maybe.map messageSummaryAttribute msg.summary
            , Maybe.map messageDetailAttribute msg.detail
            ]


messageSummaryAttribute : String -> Html Msg
messageSummaryAttribute summary =
    strong [] [ text summary ]


messageDetailAttribute : String -> Html Msg
messageDetailAttribute detail =
    pre [] [ text detail ]


formattedTime : Time.Zone -> Time.Posix -> String
formattedTime timezone time =
    View.Utils.DateFormatter.format timezone time
