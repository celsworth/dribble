module Update.ResetTorrentGroupSelection exposing (update)

import Model exposing (..)
import Model.TorrentGroups exposing (..)


update : Model -> ( Model, Cmd Msg )
update model =
    let
        newGroups =
            model.torrentGroups
                |> groupsAfterDeselect
    in
    model
        |> setTorrentGroups newGroups
        |> noCmd


groupsAfterDeselect : TorrentGroups -> TorrentGroups
groupsAfterDeselect torrentGroups =
    { torrentGroups
        | byStatus = deselectAllInStatusGroup torrentGroups.byStatus
        , byLabel = deselectAllInGroup torrentGroups.byLabel
        , byTracker = deselectAllInGroup torrentGroups.byTracker
    }
