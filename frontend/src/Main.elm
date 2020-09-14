module Main exposing (..)

import Browser
import Config exposing (Config, decodeConfigOrDefault, saveConfig)
import Html exposing (..)
import Html.Events exposing (onClick)
import JSON exposing (DecodedData(..))
import Json.Decode as JD
import Json.Encode as JE
import Ports exposing (messageReceiver, sendMessage)
import Table exposing (torrentTable)
import Torrent exposing (Torrent)



-- MAIN


main : Program JD.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { config : Config
    , torrents : List Torrent
    , error : Maybe String
    }


init : JD.Value -> ( Model, Cmd Msg )
init flags =
    ( { config = Config.decodeConfigOrDefault flags
      , torrents = []
      , error = Nothing
      }
    , getTorrents
    )


getTorrents : Cmd Msg
getTorrents =
    sendMessage JSON.getTorrentsRequest



-- UPDATE


type Msg
    = RefreshClicked
    | SaveConfigClicked
    | WebsocketData (Result JD.Error DecodedData)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RefreshClicked ->
            ( model, getTorrents )

        SaveConfigClicked ->
            ( model, Config.saveConfig model.config )

        WebsocketData response ->
            ( processWebsocketData model response, Cmd.none )


processWebsocketData : Model -> Result JD.Error DecodedData -> Model
processWebsocketData model response =
    case response of
        Ok data ->
            case data of
                Torrents newTorrents ->
                    { model | torrents = newTorrents }

                JSON.Error errStr ->
                    { model | error = Just errStr }

        Result.Err errStr ->
            -- meh it'll do for now. this is used when we get invalid JSON
            { model | error = Just (JD.errorToString errStr) }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver (WebsocketData << JSON.decodeString)



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick RefreshClicked ]
            [ text "Refresh" ]
        , button [ onClick SaveConfigClicked ]
            [ text "Save Config" ]
        , div
            []
            [ p []
                [ errorString model.error ]
            , torrentTable model.torrents
            ]
        ]


errorString : Maybe String -> Html Msg
errorString error =
    case error of
        Just str ->
            text str

        Nothing ->
            text "no error, yay!"
