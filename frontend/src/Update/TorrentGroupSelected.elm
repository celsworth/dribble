module Update.TorrentGroupSelected exposing (update)

import Model exposing (..)
import Model.TorrentGroups exposing (..)


update : GroupType -> Model -> ( Model, Cmd Msg )
update groupType model =
    let
        torrentGroups =
            model.torrentGroups

        newGroups =
            case groupType of
                ByStatus statusGroupType ->
                    torrentGroups
                        |> deselectAllStatusesExcept statusGroupType
                        |> toggleStatusSelected statusGroupType

                ByLabel label ->
                    model.torrentGroups
                        |> deselectAllLabelsExcept label
                        |> toggleLabelSelected label

                ByTracker tracker ->
                    model.torrentGroups
                        |> deselectAllTrackersExcept tracker
                        |> toggleTrackerSelected tracker
    in
    model
        |> setTorrentGroups newGroups
        |> noCmd


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


deselectAllLabelsExcept : String -> TorrentGroups -> TorrentGroups
deselectAllLabelsExcept key torrentGroups =
    { torrentGroups
        | byLabel =
            Model.TorrentGroups.deselectAllExcept key torrentGroups.byLabel
    }


toggleLabelSelected : String -> TorrentGroups -> TorrentGroups
toggleLabelSelected key torrentGroups =
    { torrentGroups
        | byLabel =
            Model.TorrentGroups.toggleSelected key torrentGroups.byLabel
    }


deselectAllTrackersExcept : String -> TorrentGroups -> TorrentGroups
deselectAllTrackersExcept key torrentGroups =
    { torrentGroups
        | byTracker =
            Model.TorrentGroups.deselectAllExcept key torrentGroups.byTracker
    }


toggleTrackerSelected : String -> TorrentGroups -> TorrentGroups
toggleTrackerSelected key torrentGroups =
    { torrentGroups
        | byTracker =
            Model.TorrentGroups.toggleSelected key torrentGroups.byTracker
    }
