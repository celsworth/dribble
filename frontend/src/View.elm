module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse
import Model exposing (..)
import Model.Utils.TorrentAttribute
import View.DragBar
import View.Preferences
import View.TorrentTable


view : Model -> Html Msg
view model =
    div (viewAttributes model)
        [ View.Preferences.view model
        , View.DragBar.view model
        , header model
        , body model
        ]


viewAttributes : Model -> List (Attribute Msg)
viewAttributes model =
    viewAttributesIfDragging model


viewAttributesIfDragging : Model -> List (Attribute Msg)
viewAttributesIfDragging model =
    case model.dragging of
        Just dragging ->
            [ -- if we're dragging, show a resize cursor all the time
              class "resizing-x"
            , Html.Events.Extra.Mouse.onUp
                (\e -> MouseUpMsg dragging e.clientPos)
            , Html.Events.Extra.Mouse.onMove
                (\e -> MouseMoveMsg dragging e.clientPos)
            ]

        Nothing ->
            []


header : Model -> Html Msg
header model =
    div []
        [ button [ onClick RefreshClicked ] [ text "Refresh" ]
        , button [ onClick SaveConfigClicked ] [ text "Save Config" ]
        , button [ onClick ShowPreferencesClicked ] [ text "Preferences" ]
        , toggleTorrentAttributeVisibilityButton CreationTime
        , toggleTorrentAttributeVisibilityButton StartedTime
        , div [] [ p [] [ messages model ] ]
        ]


toggleTorrentAttributeVisibilityButton : TorrentAttribute -> Html Msg
toggleTorrentAttributeVisibilityButton attribute =
    let
        str =
            "Toggle "
                ++ Model.Utils.TorrentAttribute.attributeToString attribute
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
    View.TorrentTable.view model
