module Utils.Mouse exposing (..)

import Html
import Html.Events
import Html.Events.Extra.Mouse exposing (..)
import Json.Decode as JD



-- Reproduction of half of Mouse.Extra, just so I can add metaKey.


type Button
    = ErrorButton
    | MainButton
    | MiddleButton
    | SecondButton
    | BackButton
    | ForwardButton


type alias Keys =
    { alt : Bool
    , ctrl : Bool
    , meta : Bool
    , shift : Bool
    }


type alias Position =
    { x : Float
    , y : Float
    }


type alias Event =
    { keys : Keys
    , button : Button -- imported
    , clientPos : Position
    , offsetPos : Position
    , pagePos : Position
    , screenPos : Position
    }


eventDecoder : JD.Decoder Event
eventDecoder =
    JD.map6 Event keys buttonDecoder clientPos offsetPos pagePos screenPos


keys : JD.Decoder Keys
keys =
    JD.map4 Keys
        (JD.field "altKey" JD.bool)
        (JD.field "ctrlKey" JD.bool)
        (JD.field "metaKey" JD.bool)
        (JD.field "shiftKey" JD.bool)


buttonDecoder : JD.Decoder Button
buttonDecoder =
    JD.map buttonFromId
        (JD.field "button" JD.int)


buttonFromId : Int -> Button
buttonFromId id =
    case id of
        0 ->
            MainButton

        1 ->
            MiddleButton

        2 ->
            SecondButton

        3 ->
            BackButton

        4 ->
            ForwardButton

        _ ->
            ErrorButton


clientPos : JD.Decoder Position
clientPos =
    JD.map2 (\x y -> { x = x, y = y })
        (JD.field "clientX" JD.float)
        (JD.field "clientY" JD.float)


offsetPos : JD.Decoder Position
offsetPos =
    JD.map2 (\x y -> { x = x, y = y })
        (JD.field "offsetX" JD.float)
        (JD.field "offsetY" JD.float)


pagePos : JD.Decoder Position
pagePos =
    JD.map2 (\x y -> { x = x, y = y })
        (JD.field "pageX" JD.float)
        (JD.field "pageY" JD.float)


screenPos : JD.Decoder Position
screenPos =
    JD.map2 (\x y -> { x = x, y = y })
        (JD.field "screenX" JD.float)
        (JD.field "screenY" JD.float)



---


onDown : (Event -> msg) -> Html.Attribute msg
onDown =
    onWithOptions "mousedown" defaultOptions


onMove : (Event -> msg) -> Html.Attribute msg
onMove =
    onWithOptions "mousemove" defaultOptions


onUp : (Event -> msg) -> Html.Attribute msg
onUp =
    onWithOptions "mouseup" defaultOptions


onClick : (Event -> msg) -> Html.Attribute msg
onClick =
    onWithOptions "click" defaultOptions


onContextMenu : (Event -> msg) -> Html.Attribute msg
onContextMenu =
    onWithOptions "contextmenu" defaultOptions


defaultOptions : EventOptions
defaultOptions =
    { stopPropagation = False
    , preventDefault = True
    }


onWithOptions : String -> EventOptions -> (Event -> msg) -> Html.Attribute msg
onWithOptions event options tag =
    eventDecoder
        |> JD.map (\ev -> { message = tag ev, stopPropagation = options.stopPropagation, preventDefault = options.preventDefault })
        |> Html.Events.custom event
