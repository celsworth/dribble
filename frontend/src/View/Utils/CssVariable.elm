module View.Utils.CssVariable exposing (..)

import Html exposing (..)



{- this is an evil hack because neither elm/html nor elm/css support
   css variables.

   View.Utils.CssVariable.style [ ( "--table-cell-height", "21px" ) ]

   produces:

   <style> :root { --table-cell-height: 21px } </style>
-}


style : List ( String, String ) -> Html msg
style vars =
    let
        fn =
            \( n, c ) -> n ++ ": " ++ c

        output =
            List.map fn vars |> String.join ";"
    in
    node "style" [] [ text <| ":root { " ++ output ++ " }" ]
