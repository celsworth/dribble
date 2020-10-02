module Model.Window exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional)
import Json.Encode as E


type alias ResizeDetails =
    { id : String
    , width : Int
    , height : Int
    }


type alias Config =
    { visible : Bool
    , width : Int
    , height : Int
    }


type Type
    = Preferences
    | Logs


toggleVisible : Config -> Config
toggleVisible config =
    { config | visible = not config.visible }



--- JSON ENCODER


encode : Config -> E.Value
encode config =
    E.object
        [ ( "visible", E.bool config.visible )
        , ( "width", E.int config.width )
        , ( "height", E.int config.height )
        ]



-- JSON DECODERS


decoder : D.Decoder Config
decoder =
    D.succeed Config
        |> optional "visible" D.bool False
        |> optional "width" D.int 200
        |> optional "height" D.int 200


windowResizeDetailsDecoder : D.Decoder ResizeDetails
windowResizeDetailsDecoder =
    D.map3 ResizeDetails
        (D.field "id" D.string)
        (D.field "width" D.int)
        (D.field "height" D.int)



-- MISC


idToType : String -> Type
idToType id =
    -- strictly this should be Maybe, because id could be anything.
    -- in practise, we set it in our JS so pretty confident this is ok.
    case id of
        "preferences" ->
            Preferences

        -- cheating
        _ ->
            Logs
