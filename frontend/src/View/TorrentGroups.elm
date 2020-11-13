module View.TorrentGroups exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy
import Model exposing (..)
import Model.Torrent
import Model.TorrentGroups exposing (..)
import Utils.Mouse as Mouse
import View.Utils.TorrentStatusIcon


view : Model -> Html Msg
view model =
    Html.Lazy.lazy torrentGroupsView model.torrentGroups


torrentGroupsView : TorrentGroups -> Html Msg
torrentGroupsView torrentGroups =
    div [ class "torrent-groups" ]
        [ torrentGroupReset torrentGroups.byStatus.all
        , torrentGroupForStatuses torrentGroups.byStatus
        , torrentGroupForLabels torrentGroups.byLabel
        , torrentGroupForTrackers torrentGroups.byTracker
        ]


torrentGroupReset : Details -> Html Msg
torrentGroupReset all =
    div [ class "torrent-group" ]
        [ ul []
            [ resetListItem all ]
        ]


torrentGroupForStatuses : StatusGroup -> Html Msg
torrentGroupForStatuses group =
    div [ class "torrent-group" ]
        [ p [ class "header" ] [ text "Status" ]
        , ul []
            [ listItemForStatus "Seeding" Seeding group.seeding
            , listItemForStatus "Downloading" Downloading group.downloading
            , listItemForStatus "Hashing" Hashing group.hashing
            , listItemForStatus "Paused" Paused group.paused
            , listItemForStatus "Stopped" Stopped group.stopped
            , listItemForStatus "Errored" Errored group.errored
            , hr [] []
            , listItemForStatus "Active" Active group.active
            , listItemForStatus "Inactive" Inactive group.inactive
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


resetListItem : Details -> Html Msg
resetListItem details =
    li []
        [ button [ onClick ResetTorrentGroupSelection ] [ text "Reset / All" ]
        , span [ class "value" ] [ text <| String.fromInt details.count ]
        ]


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
