module Update.TorrentGroupSelected exposing (update)

import Dict
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


toggleLabelSelected : String -> TorrentGroups -> TorrentGroups
toggleLabelSelected key torrentGroups =
    { torrentGroups | byLabel = toggleSelected key torrentGroups.byLabel }


deselectAllLabelsExcept : String -> TorrentGroups -> TorrentGroups
deselectAllLabelsExcept key torrentGroups =
    { torrentGroups | byLabel = deselectAllExcept key torrentGroups.byLabel }


toggleTrackerSelected : String -> TorrentGroups -> TorrentGroups
toggleTrackerSelected key torrentGroups =
    { torrentGroups | byTracker = toggleSelected key torrentGroups.byTracker }


deselectAllTrackersExcept : String -> TorrentGroups -> TorrentGroups
deselectAllTrackersExcept key torrentGroups =
    { torrentGroups | byTracker = deselectAllExcept key torrentGroups.byTracker }


toggleSelected : String -> GenericGroup -> GenericGroup
toggleSelected key group =
    Model.TorrentGroups.toggleSelected key group


deselectAllExcept : String -> GenericGroup -> GenericGroup
deselectAllExcept key group =
    Model.TorrentGroups.deselectAllExcept key group
