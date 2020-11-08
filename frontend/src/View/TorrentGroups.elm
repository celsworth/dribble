module View.TorrentGroups exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy
import Model exposing (..)
import Model.Torrent
import Model.TorrentGroups exposing (Details, GenericGroup, StatusGroup, TorrentGroups)
import View.Utils.TorrentStatusIcon


view : Model -> Html Msg
view model =
    Html.Lazy.lazy torrentGroupsView model.torrentGroups


torrentGroupsView : TorrentGroups -> Html Msg
torrentGroupsView torrentGroups =
    div [ class "torrent-groups" ]
        [ torrentGroupForStatuses "Status" torrentGroups.byStatus
        , torrentGroupForLabels "Labels" torrentGroups.byLabel
        , torrentGroupForTrackers "Trackers" torrentGroups.byTracker
        ]


torrentGroupForStatuses : String -> StatusGroup -> Html Msg
torrentGroupForStatuses header group =
    div [ class "torrent-group" ]
        [ p [ class "header" ] [ text header ]
        , ul []
            [ listItem [ text "All Torrents" ] group.all
            , hr [] []
            , listItemForStatus "Active" group.active
            , listItemForStatus "Inactive" group.inactive
            , hr [] []
            , listItemForStatus "Seeding" group.seeding
            , listItemForStatus "Downloading" group.downloading
            , listItemForStatus "Hashing" group.hashing
            , listItemForStatus "Paused" group.paused
            , listItemForStatus "Stopped" group.stopped
            , listItemForStatus "Errored" group.errored
            ]
        ]


listItemForStatus : String -> Details -> Html Msg
listItemForStatus label details =
    listItem [ statusIcon label, text label ] details


statusIcon : String -> Html Msg
statusIcon status =
    Maybe.withDefault (text "") <|
        Maybe.map
            View.Utils.TorrentStatusIcon.view
            (Model.Torrent.stringToStatus status)


torrentGroupForLabels : String -> GenericGroup -> Html Msg
torrentGroupForLabels header group =
    div [ class "torrent-group" ]
        [ p [ class "header" ] [ text header ]
        , ul [] <| List.map listItemForLabel (Dict.toList group)
        ]


listItemForLabel : ( String, Details ) -> Html Msg
listItemForLabel ( label, details ) =
    let
        nonEmptyLabel =
            if String.isEmpty label then
                text "(No Label)"

            else
                text label
    in
    listItem [ nonEmptyLabel ] details


torrentGroupForTrackers : String -> GenericGroup -> Html Msg
torrentGroupForTrackers header group =
    div [ class "torrent-group" ]
        [ p [ class "header" ] [ text header ]
        , ul [] <| List.map listItemForTracker (Dict.toList group)
        ]


listItemForTracker : ( String, Details ) -> Html Msg
listItemForTracker ( label, details ) =
    listItem [ trackerFavicon label, text label ] details


trackerFavicon : String -> Html Msg
trackerFavicon domain =
    img [ class "favicon", src <| "/proxy/" ++ domain ++ "/favicon.ico" ] []


listItem : List (Html Msg) -> Details -> Html Msg
listItem labelContent details =
    let
        kls =
            if details.selected then
                "selected"

            else
                ""
    in
    li
        [ class kls
        ]
        [ span [ class "label" ] labelContent
        , span [ class "value" ] [ text <| String.fromInt details.count ]
        ]
