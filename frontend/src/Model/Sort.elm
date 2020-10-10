module Model.Sort exposing (..)

import Json.Decode as D
import Json.Encode as E


type SortDirection
    = Asc
    | Desc



-- JSON ENCODING


encodeSortDirection : SortDirection -> E.Value
encodeSortDirection direction =
    case direction of
        Asc ->
            E.string "asc"

        Desc ->
            E.string "desc"



-- JSON DECODING


sortDirectionDecoder : D.Decoder SortDirection
sortDirectionDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "asc" ->
                        D.succeed Asc

                    "desc" ->
                        D.succeed Desc

                    _ ->
                        D.fail <| "unknown direction " ++ input
            )
