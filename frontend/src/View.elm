module View exposing (view)

import Html exposing (..)
import Html.Events exposing (onClick)
import Model exposing (..)
import View.TorrentTable
import View.Utils.TorrentAttributeMethods


view : Model -> Html Msg
view model =
    div []
        [ header model
        , body model
        ]


header : Model -> Html Msg
header model =
    div []
        [ button [ onClick RefreshClicked ] [ text "Refresh" ]
        , button [ onClick SaveConfigClicked ] [ text "Save Config" ]
        , toggleTorrentAttributeVisibilityButton CreationTime
        , toggleTorrentAttributeVisibilityButton StartedTime
        , div [] [ p [] [ messages model ] ]
        ]


toggleTorrentAttributeVisibilityButton : TorrentAttribute -> Html Msg
toggleTorrentAttributeVisibilityButton attribute =
    let
        str =
            "Toggle "
                ++ View.Utils.TorrentAttributeMethods.attributeToString attribute
    in
    button [ onClick <| ToggleTorrentAttributeVisibility attribute ]
        [ text str ]


messages : Model -> Html Msg
messages model =
    div [] (List.map message model.messages)


message : Message -> Html Msg
message msg =
    let
        severity =
            case msg.severity of
                InfoSeverity ->
                    Nothing

                WarningSeverity ->
                    Just "WARNING: "

                ErrorSeverity ->
                    Just "ERROR: "
    in
    p [] [ text <| Maybe.withDefault "" severity ++ msg.message ]


body : Model -> Html Msg
body model =
    div [] [ View.TorrentTable.view model ]
