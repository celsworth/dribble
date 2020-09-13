module Table exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy)
import Torrent exposing (..)


torrentTable : List Torrent -> Html msg
torrentTable torrents =
    table []
        (List.concat
            [ [ torrentTableHeader ]
            , [ Keyed.node "tbody"
                    []
                    (List.map keyedTorrentTableRow torrents)
              ]
            ]
        )


torrentTableHeader : Html msg
torrentTableHeader =
    thead [] [ th [] [ text "Name" ] ]


keyedTorrentTableRow : Torrent -> ( String, Html msg )
keyedTorrentTableRow torrent =
    ( torrent.hash, lazy torrentTableRow torrent )


torrentTableRow : Torrent -> Html msg
torrentTableRow torrent =
    tr []
        [ text torrent.name ]
