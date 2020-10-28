module Model.MousePosition exposing (..)

{- Html.Events.Extra.Mouse does expose a Mouse.Position but it's a (Float, Float)
   and I prefer { x: Float, y: Float }. It makes extraction of either coord easier
   as well, which is useful for dragbars.
-}


type alias MousePosition =
    { x : Float
    , y : Float
    }


reconstructClientPos : { e | clientPos : ( Float, Float ) } -> { x : Float, y : Float }
reconstructClientPos =
    {- converts (x, y) to { x: x, y: y } -}
    \event ->
        let
            ( x, y ) =
                event.clientPos
        in
        { x = x, y = y }
