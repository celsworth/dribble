module Model.TorrentGroups exposing (..)

import Dict exposing (Dict)
import Model.Torrent exposing (Torrent)
import Model.TorrentFilter as TF


type alias Details =
    { count : Int
    , selected : Bool
    , expr : TF.Expr
    }


type GroupType
    = ByStatus StatusGroupType
    | ByLabel String
    | ByTracker String


type StatusGroupType
    = All
    | Seeding
    | Downloading
    | Hashing
    | Paused
    | Stopped
    | Errored
    | Active
    | Inactive


type alias StatusGroup =
    { all : Details
    , seeding : Details
    , downloading : Details
    , hashing : Details
    , paused : Details
    , stopped : Details
    , errored : Details
    , active : Details
    , inactive : Details
    }


type alias GenericGroup =
    Dict String Details


type alias TorrentGroups =
    { byStatus : StatusGroup
    , byLabel : GenericGroup
    , byTracker : GenericGroup
    }


empty : TorrentGroups
empty =
    { byStatus = initialStatus
    , byLabel = Dict.empty
    , byTracker = Dict.empty
    }


initialStatus : StatusGroup
initialStatus =
    { all =
        { count = 0
        , selected = True
        , expr = TF.Unset
        }
    , seeding =
        { count = 0
        , selected = False
        , expr = TF.Status TF.EqStatus Model.Torrent.Seeding
        }
    , downloading =
        { count = 0
        , selected = False
        , expr = TF.Done TF.LT 100
        }
    , hashing =
        { count = 0
        , selected = False
        , expr = TF.Status TF.EqStatus Model.Torrent.Hashing
        }
    , active =
        { count = 0
        , selected = False
        , expr =
            TF.OrExpr
                [ TF.DownRate TF.GT 0 TF.Nothing
                , TF.UpRate TF.GT 0 TF.Nothing
                ]
        }
    , inactive =
        { count = 0
        , selected = False
        , expr =
            TF.AndExpr
                [ TF.DownRate TF.EqNum 0 TF.Nothing
                , TF.UpRate TF.EqNum 0 TF.Nothing
                ]
        }
    , paused =
        { count = 0
        , selected = False
        , expr = TF.Status TF.EqStatus Model.Torrent.Paused
        }
    , stopped =
        { count = 0
        , selected = False
        , expr = TF.Status TF.EqStatus Model.Torrent.Stopped
        }
    , errored =
        { count = 0
        , selected = False
        , expr = TF.Status TF.EqStatus Model.Torrent.Errored
        }
    }



-- ZEROING


zeroTorrentGroups : TorrentGroups -> TorrentGroups
zeroTorrentGroups torrentGroups =
    { torrentGroups
        | byStatus = zeroByStatus torrentGroups.byStatus
        , byLabel = Dict.map (\_ v -> zeroDetails v) torrentGroups.byLabel
        , byTracker = Dict.map (\_ v -> zeroDetails v) torrentGroups.byTracker
    }


zeroByStatus : StatusGroup -> StatusGroup
zeroByStatus statusGroup =
    { all = zeroDetails statusGroup.all
    , seeding = zeroDetails statusGroup.seeding
    , downloading = zeroDetails statusGroup.downloading
    , hashing = zeroDetails statusGroup.hashing
    , paused = zeroDetails statusGroup.paused
    , stopped = zeroDetails statusGroup.stopped
    , errored = zeroDetails statusGroup.errored
    , active = zeroDetails statusGroup.active
    , inactive = zeroDetails statusGroup.inactive
    }


zeroDetails : Details -> Details
zeroDetails details =
    { details | count = 0 }



-- CREATION / UPDATE


groups : TorrentGroups -> List Torrent -> TorrentGroups
groups torrentGroups torrents =
    let
        zeroed =
            zeroTorrentGroups torrentGroups
    in
    { byStatus = updateByStatus zeroed.byStatus torrents
    , byLabel = updateByLabel zeroed.byLabel torrents
    , byTracker = updateByTracker zeroed.byTracker torrents
    }


updateByStatus : StatusGroup -> List Torrent -> StatusGroup
updateByStatus group torrents =
    List.foldr
        (\torrent carry -> updateStatus torrent carry)
        group
        torrents


updateByLabel : GenericGroup -> List Torrent -> GenericGroup
updateByLabel group torrents =
    let
        expr =
            TF.Label << TF.EqStr << TF.CaseSensitive
    in
    List.foldr
        (\torrent carry -> incrementKey expr torrent.label carry)
        group
        torrents


updateByTracker : GenericGroup -> List Torrent -> GenericGroup
updateByTracker group torrents =
    let
        expr =
            TF.Tracker << TF.EqStr << TF.CaseSensitive
    in
    List.foldr
        (\torrent carry ->
            List.foldr
                (\host carry2 -> incrementKey expr host carry2)
                carry
                torrent.trackerHosts
        )
        group
        torrents


updateStatus : Torrent -> StatusGroup -> StatusGroup
updateStatus torrent statusGroup =
    statusGroup
        |> updateStatusAll
        |> updateStatusSeeding torrent
        |> updateStatusDownloading torrent
        |> updateStatusHashing torrent
        |> updateStatusActive torrent
        |> updateStatusPaused torrent
        |> updateStatusStopped torrent
        |> updateStatusErrored torrent


updateStatusAll : StatusGroup -> StatusGroup
updateStatusAll statusGroup =
    { statusGroup | all = increment statusGroup.all }


updateStatusSeeding : Torrent -> StatusGroup -> StatusGroup
updateStatusSeeding torrent statusGroup =
    if torrent.status == Model.Torrent.Seeding then
        { statusGroup | seeding = increment statusGroup.seeding }

    else
        statusGroup


updateStatusDownloading : Torrent -> StatusGroup -> StatusGroup
updateStatusDownloading torrent statusGroup =
    if torrent.donePercent < 100 then
        { statusGroup | downloading = increment statusGroup.downloading }

    else
        statusGroup


updateStatusHashing : Torrent -> StatusGroup -> StatusGroup
updateStatusHashing torrent statusGroup =
    if torrent.status == Model.Torrent.Hashing then
        { statusGroup | hashing = increment statusGroup.hashing }

    else
        statusGroup


updateStatusActive : Torrent -> StatusGroup -> StatusGroup
updateStatusActive torrent statusGroup =
    if torrent.downloadRate > 0 || torrent.uploadRate > 0 then
        { statusGroup | active = increment statusGroup.active }

    else
        { statusGroup | inactive = increment statusGroup.inactive }


updateStatusPaused : Torrent -> StatusGroup -> StatusGroup
updateStatusPaused torrent statusGroup =
    if torrent.status == Model.Torrent.Paused then
        { statusGroup | paused = increment statusGroup.paused }

    else
        statusGroup


updateStatusStopped : Torrent -> StatusGroup -> StatusGroup
updateStatusStopped torrent statusGroup =
    if torrent.status == Model.Torrent.Stopped then
        { statusGroup | stopped = increment statusGroup.stopped }

    else
        statusGroup


updateStatusErrored : Torrent -> StatusGroup -> StatusGroup
updateStatusErrored torrent statusGroup =
    if torrent.status == Model.Torrent.Errored then
        { statusGroup | errored = increment statusGroup.errored }

    else
        statusGroup



-- MISC UPDATERS


incrementKey : (String -> TF.Expr) -> String -> GenericGroup -> GenericGroup
incrementKey expr key carry =
    Dict.update
        key
        (\existingCount ->
            Maybe.map (\e -> increment e) existingCount
                |> Maybe.withDefault
                    { count = 1
                    , selected = False
                    , expr = expr key
                    }
                |> Just
        )
        carry


deselectAllExcept : String -> GenericGroup -> GenericGroup
deselectAllExcept key group =
    let
        fn =
            \k v ->
                if k /= key then
                    { v | selected = False }

                else
                    v
    in
    Dict.map fn group


toggleSelected : String -> GenericGroup -> GenericGroup
toggleSelected key group =
    let
        fn =
            \d -> { d | selected = not d.selected }
    in
    Dict.update key (Maybe.map fn) group


increment : Details -> Details
increment details =
    { details | count = details.count + 1 }



-- SELECTORS


selectedExprs : GenericGroup -> List TF.Expr
selectedExprs group =
    let
        fn =
            \_ v ->
                if v.selected then
                    Just v.expr

                else
                    Nothing
    in
    group
        |> Dict.map fn
        |> Dict.values
        |> List.filterMap identity
