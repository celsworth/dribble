module View.TorrentGroups exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy
import Model exposing (..)
import Utils.Mouse as Mouse
import Model.Torrent
import Model.TorrentGroups exposing (..)
import View.Utils.TorrentStatusIcon


view : Model -> Html Msg
view model =
    Html.Lazy.lazy torrentGroupsView model.torrentGroups


torrentGroupsView : TorrentGroups -> Html Msg
torrentGroupsView torrentGroups =
    div [ class "torrent-groups" ]
        [ torrentGroupForStatuses torrentGroups.byStatus
        , torrentGroupForLabels torrentGroups.byLabel
        , torrentGroupForTrackers torrentGroups.byTracker
        ]


torrentGroupForStatuses : StatusGroup -> Html Msg
torrentGroupForStatuses group =
    div [ class "torrent-group" ]
        [ p [ class "header" ] [ text "Status" ]
        , ul []
            [ listItem (ByStatus All) [ text "All" ] group.all
            , hr [] []
            , listItemForStatus "Active" Active group.active
            , listItemForStatus "Inactive" Inactive group.inactive
            , hr [] []
            , listItemForStatus "Seeding" Seeding group.seeding
            , listItemForStatus "Downloading" Downloading group.downloading
            , listItemForStatus "Hashing" Hashing group.hashing
            , listItemForStatus "Paused" Paused group.paused
            , listItemForStatus "Stopped" Stopped group.stopped
            , listItemForStatus "Errored" Errored group.errored
            ]
        ]


listItemForStatus : String -> StatusGroupType -> Details -> Html Msg
listItemForStatus label groupType details =
    listItem (ByStatus groupType) [ statusIcon label, text label ] details


statusIcon : String -> Html Msg
statusIcon status =
    Maybe.withDefault (text "") <|
        Maybe.map
            View.Utils.TorrentStatusIcon.view
            (Model.Torrent.stringToStatus status)


torrentGroupForLabels : GenericGroup -> Html Msg
torrentGroupForLabels group =
    div [ class "torrent-group" ]
        [ p [ class "header" ] [ text "Labels" ]
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
    listItem
        (ByLabel label)
        [ nonEmptyLabel ]
        details


torrentGroupForTrackers : GenericGroup -> Html Msg
torrentGroupForTrackers group =
    div [ class "torrent-group" ]
        [ p [ class "header" ] [ text "Trackers" ]
        , ul [] <| List.map listItemForTracker (Dict.toList group)
        ]


listItemForTracker : ( String, Details ) -> Html Msg
listItemForTracker ( label, details ) =
    listItem
        (ByTracker label)
        [ trackerFavicon label, text label ]
        details


trackerFavicon : String -> Html Msg
trackerFavicon domain =
    img [ class "favicon", src <| "/proxy/" ++ domain ++ "/favicon.ico" ] []


listItem : GroupType -> List (Html Msg) -> Details -> Html Msg
listItem groupType labelContent details =
    let
        kls =
            if details.selected then
                "selected"

            else
                ""
    in
    li
        [ Mouse.onClick (\e -> TorrentGroupSelected groupType e.keys)
        , class kls
        ]
        [ span [ class "label" ] labelContent
        , span [ class "value" ] [ text <| String.fromInt details.count ]
        ]
