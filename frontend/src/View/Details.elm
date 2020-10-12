module View.Details exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Torrent exposing (Torrent)
import View.SpeedChart


view : Model -> Html Msg
view model =
    section [ class "details" ]
        [ div []
            (List.filterMap identity
                [ maybeTorrentDetails model ]
            )
        , View.SpeedChart.view model
        ]


maybeTorrentDetails : Model -> Maybe (Html Msg)
maybeTorrentDetails model =
    model.selectedTorrentHash
        |> Maybe.andThen (\s -> Dict.get s model.torrentsByHash)
        |> Maybe.map (torrentDetails model)


torrentDetails : Model -> Torrent -> Html Msg
torrentDetails model torrent =
    div [] [ text torrent.name ]
