module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse
import Model exposing (..)
import Model.Utils.TorrentAttribute
import View.Preferences
import View.TorrentTable


view : Model -> Html Msg
view model =
    div (viewAttributes model)
        [ View.Preferences.view model
        , navigation model
        , View.TorrentTable.view model
        , footer [ class "footer" ] []
        ]


viewAttributes : Model -> List (Attribute Msg)
viewAttributes model =
    let
        resizingAttributes =
            Maybe.map viewAttributesForResizeOp model.torrentAttributeResizeOp
                |> Maybe.withDefault []
    in
    List.append [] resizingAttributes


viewAttributesForResizeOp : TorrentAttributeResizeOp -> List (Attribute Msg)
viewAttributesForResizeOp resizeOp =
    [ class "resizing-x"
    , Html.Events.Extra.Mouse.onUp
        (\e -> TorrentAttributeResizeEnded resizeOp (reconstructClientPos e))
    , Html.Events.Extra.Mouse.onMove
        (\e -> TorrentAttributeResized resizeOp (reconstructClientPos e))
    ]


reconstructClientPos : { e | clientPos : ( Float, Float ) } -> MousePosition
reconstructClientPos event =
    {- this mess converts (x, y) to { x: x, y: y } -}
    let
        ( x, y ) =
            event.clientPos
    in
    { x = x, y = y }


navigation : Model -> Html Msg
navigation model =
    section [ class "navigation" ]
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
