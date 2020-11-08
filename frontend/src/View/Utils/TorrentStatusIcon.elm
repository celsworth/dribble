module View.Utils.TorrentStatusIcon exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model.Torrent


view : Model.Torrent.Status -> Html msg
view status =
    case status of
        Model.Torrent.Seeding ->
            icon "seeding" "fa-arrow-up"

        Model.Torrent.Active ->
            icon "active" "fa-exchange-alt fa-rotate-90"

        Model.Torrent.Inactive ->
            icon "inactive" "fa-exchange-alt fa-rotate-90"

        Model.Torrent.Errored ->
            icon "errored" "fa-exclamation"

        Model.Torrent.Downloading ->
            icon "downloading" "fa-arrow-down"

        Model.Torrent.Paused ->
            icon "paused" "fa-pause"

        Model.Torrent.Stopped ->
            icon "stopped" "fa-circle"

        Model.Torrent.Hashing ->
            icon "hashing" "fa-sync"


icon : String -> String -> Html msg
icon kls iconKls =
    span [ class ("torrent-status " ++ kls ++ " fa-stack") ]
        [ i [ class "fas fa-square fa-stack-2x" ] []
        , i [ class ("fas " ++ iconKls ++ " fa-inverse fa-stack-1x") ] []
        ]
