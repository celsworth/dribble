port module Main exposing (..)

import Browser
import Decoder exposing (DecodedData(..))
import Html exposing (..)
import Json.Decode as JD
import Table exposing (torrentTable)
import Torrent exposing (Torrent)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS


port sendMessage : String -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg



-- MODEL


type alias Model =
    { torrents : List Torrent
    , error : Maybe String
    }


init : () -> ( Model, Cmd Msg )
init flags =
    ( { torrents = [], error = Nothing }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Send
    | WebsocketData (Result JD.Error DecodedData)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Send ->
            ( model
            , sendMessage "msg"
            )

        WebsocketData response ->
            parseWebsocketData model response


parseWebsocketData : Model -> Result JD.Error DecodedData -> ( Model, Cmd Msg )
parseWebsocketData model response =
    case response of
        Ok data ->
            case data of
                Torrents newTorrents ->
                    ( { model | torrents = newTorrents }, Cmd.none )

                Decoder.Err errStr ->
                    ( { model | error = Just errStr }, Cmd.none )

        Result.Err errStr ->
            -- meh it'll do for now. this is used when we get invalid JSON
            ( { model | error = Just (JD.errorToString errStr) }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver (WebsocketData << Decoder.decodeString)



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ p []
            [ errorString model.error ]
        , torrentTable model.torrents
        ]


errorString : Maybe String -> Html Msg
errorString error =
    case error of
        Just str ->
            text str

        Nothing ->
            text "no error, yay!"
