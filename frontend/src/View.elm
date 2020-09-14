module View exposing (view)

import Html exposing (..)
import Html.Events exposing (onClick)
import Model exposing (..)
import View.TorrentTable


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
        , div [] [ p [] [ errorString model.error ] ]
        ]


body : Model -> Html Msg
body model =
    div [] [ View.TorrentTable.view model ]


errorString : Maybe String -> Html Msg
errorString error =
    case error of
        Just str ->
            text str

        Nothing ->
            text "no error, yay!"
