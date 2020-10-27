module View.Details exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Torrent exposing (Torrent)
import View.FileTable


view : Model -> Html Msg
view model =
    section [ class "details" ]
        [ maybeTorrentDetails model |> Maybe.withDefault (div [] [])
        ]


maybeTorrentDetails : Model -> Maybe (Html Msg)
maybeTorrentDetails model =
    model.selectedTorrentHash
        |> Maybe.andThen (\s -> Dict.get s model.torrentsByHash)
        |> Maybe.map (torrentDetails model)


torrentDetails : Model -> Torrent -> Html Msg
torrentDetails model torrent =
    div
        [ style "overflow" "auto"
        , style "flex-grow" "1"
        ]
        [ View.FileTable.view model
        ]
