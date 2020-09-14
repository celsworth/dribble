module View.TorrentTable exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy)
import Model exposing (..)
import Torrent exposing (sort)


view : Model -> Html msg
view model =
    table []
        (List.concat
            [ [ torrentTableHeader ]
            , [ torrentTableBody model ]
            ]
        )


torrentTableHeader : Html msg
torrentTableHeader =
    thead []
        [ tr []
            [ th [] [ text "Name" ]
            , th [] [ text "Size" ]
            ]
        ]


torrentTableBody : Model -> Html msg
torrentTableBody model =
    Keyed.node "tbody"
        []
        (List.map keyedTorrentTableRow <| sortedTorrents model)


sortedTorrents : Model -> List Torrent
sortedTorrents model =
    Torrent.sort model


keyedTorrentTableRow : Torrent -> ( String, Html msg )
keyedTorrentTableRow torrent =
    ( torrent.hash, lazy torrentTableRow torrent )


torrentTableRow : Torrent -> Html msg
torrentTableRow torrent =
    tr []
        [ td [] [ text torrent.name ]
        , td [] [ text (String.fromInt torrent.size) ]
        ]
