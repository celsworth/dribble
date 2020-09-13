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
    thead []
        [ tr []
            [ th [] [ text "Name" ]
            , th [] [ text "Size" ]
            ]
        ]


keyedTorrentTableRow : Torrent -> ( String, Html msg )
keyedTorrentTableRow torrent =
    ( torrent.hash, lazy torrentTableRow torrent )


torrentTableRow : Torrent -> Html msg
torrentTableRow torrent =
    tr []
        [ td [] [ text torrent.name ]
        , td [] [ text (String.fromInt torrent.size) ]
        ]
