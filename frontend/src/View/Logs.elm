module View.Logs exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Message exposing (Message)
import Time
import View.Utils.DateFormatter


view : Model -> Html Msg
view model =
    section (sectionAttributes model) (sectionContents model)


sectionAttributes : Model -> List (Attribute Msg)
sectionAttributes model =
    List.filterMap identity
        [ Just <| class "logs"
        , visibleIfLogsVisible model
        ]


visibleIfLogsVisible : Model -> Maybe (Attribute Msg)
visibleIfLogsVisible model =
    if model.logsVisible then
        Just <| class "visible"

    else
        Nothing


sectionContents : Model -> List (Html Msg)
sectionContents model =
    [ i [ class "fas fa-cross" ] []
    , messageList model
    ]


messageList : Model -> Html Msg
messageList model =
    ol [] (List.map (messageItem model) model.messages)


messageItem : Model -> Message -> Html Msg
messageItem model msg =
    li [ class (messageItemClass msg.severity) ]
        [ messageTime model msg, messageContent model msg ]


messageItemClass : Model.Message.Severity -> String
messageItemClass severity =
    case severity of
        Model.Message.Info ->
            "info"

        Model.Message.Warning ->
            "warning"

        Model.Message.Error ->
            "error"


messageTime : Model -> Message -> Html Msg
messageTime model msg =
    strong [ class "time" ] [ text <| formattedTime model msg.time ]


messageContent : Model -> Message -> Html Msg
messageContent _ msg =
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


formattedTime : Model -> Time.Posix -> String
formattedTime model time =
    View.Utils.DateFormatter.format model.timezone time
