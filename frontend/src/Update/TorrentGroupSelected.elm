module Update.TorrentGroupSelected exposing (update)

import Model exposing (..)
import Model.TorrentGroups exposing (..)
import Utils.Mouse as Mouse


update : GroupType -> Mouse.Keys -> Model -> ( Model, Cmd Msg )
update groupType keys model =
    let
        newGroups =
            model.torrentGroups
                |> groupsAfterDeselect groupType keys
                |> groupsAfterToggle groupType
    in
    model
        |> setTorrentGroups newGroups
        |> noCmd


groupsAfterDeselect : GroupType -> Mouse.Keys -> TorrentGroups -> TorrentGroups
groupsAfterDeselect groupType keys torrentGroups =
    if keys.alt || keys.ctrl || keys.meta then
        torrentGroups

    else
        case groupType of
            ByStatus statusGroupType ->
                torrentGroups
                    |> deselectAllStatusesExcept statusGroupType

            ByLabel label ->
                torrentGroups
                    |> deselectAllLabelsExcept label

            ByTracker tracker ->
                torrentGroups
                    |> deselectAllTrackersExcept tracker


groupsAfterToggle : GroupType -> TorrentGroups -> TorrentGroups
groupsAfterToggle groupType torrentGroups =
    case groupType of
        ByStatus statusGroupType ->
            torrentGroups
                |> toggleStatusSelected statusGroupType

        ByLabel label ->
            torrentGroups
                |> toggleLabelSelected label

        ByTracker tracker ->
            torrentGroups
                |> toggleTrackerSelected tracker



-- STATUS


deselectAllStatusesExcept : StatusGroupType -> TorrentGroups -> TorrentGroups
deselectAllStatusesExcept key torrentGroups =
    { torrentGroups
        | byStatus =
            Model.TorrentGroups.deselectAllStatusesExcept
                key
                torrentGroups.byStatus
    }


toggleStatusSelected : StatusGroupType -> TorrentGroups -> TorrentGroups
toggleStatusSelected key torrentGroups =
    { torrentGroups
        | byStatus =
            Model.TorrentGroups.toggleStatusSelected key torrentGroups.byStatus
    }



-- LABELS


deselectAllLabelsExcept : String -> TorrentGroups -> TorrentGroups
deselectAllLabelsExcept key torrentGroups =
    { torrentGroups
        | byLabel =
            Model.TorrentGroups.deselectAllInGroupExcept key torrentGroups.byLabel
    }


toggleLabelSelected : String -> TorrentGroups -> TorrentGroups
toggleLabelSelected key torrentGroups =
    { torrentGroups
        | byLabel =
            Model.TorrentGroups.toggleSelected key torrentGroups.byLabel
    }



-- TRACKERS


deselectAllTrackersExcept : String -> TorrentGroups -> TorrentGroups
deselectAllTrackersExcept key torrentGroups =
    { torrentGroups
        | byTracker =
            Model.TorrentGroups.deselectAllInGroupExcept key torrentGroups.byTracker
    }


toggleTrackerSelected : String -> TorrentGroups -> TorrentGroups
toggleTrackerSelected key torrentGroups =
    { torrentGroups
        | byTracker =
            Model.TorrentGroups.toggleSelected key torrentGroups.byTracker
    }
