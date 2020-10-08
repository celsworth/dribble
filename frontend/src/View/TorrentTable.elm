module View.TorrentTable exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed as Keyed
import Html.Lazy
import List
import Model exposing (..)
import Model.Attribute
import Model.Config
import Model.Table
import Model.Torrent exposing (Torrent)
import Model.TorrentFilter exposing (TorrentFilter)
import Round
import Utils.Filesize
import View.DragBar
import View.Table
import View.Utils.LocalTimeNode


view : Model -> Html Msg
view model =
    if List.isEmpty model.sortedTorrents then
        section [ class "torrents loading" ]
            [ i [ class "fas fa-spinner fa-pulse" ] [] ]

    else
        section [ class "torrents" ]
            [ table []
                [ Html.Lazy.lazy View.DragBar.view model.resizeOp
                , Html.Lazy.lazy2 View.Table.header
                    model.config
                    model.config.torrentTable
                , Html.Lazy.lazy5 body
                    model.config.humanise
                    model.config.torrentTable
                    model.torrentFilter
                    model.torrentsByHash
                    model.sortedTorrents
                ]
            ]


body : Model.Config.Humanise -> Model.Table.Config -> TorrentFilter -> TorrentsByHash -> List String -> Html Msg
body humanise tableConfig torrentFilter torrentsByHash sortedTorrents =
    Keyed.node "tbody" [] <|
        List.filterMap identity
            (List.map
                (keyedRow humanise tableConfig torrentFilter torrentsByHash)
                sortedTorrents
            )


keyedRow : Model.Config.Humanise -> Model.Table.Config -> TorrentFilter -> TorrentsByHash -> String -> Maybe ( String, Html Msg )
keyedRow humanise tableConfig torrentFilter torrentsByHash hash =
    Maybe.map
        (\torrent -> ( hash, lazyRow humanise tableConfig (Just torrentFilter) torrent ))
        (Dict.get hash torrentsByHash)


lazyRow : Model.Config.Humanise -> Model.Table.Config -> Maybe TorrentFilter -> Torrent -> Html Msg
lazyRow humanise tableConfig torrentFilter torrent =
    let
        matches =
            Maybe.map (Model.TorrentFilter.torrentMatches torrent) torrentFilter
                |> Maybe.withDefault True
    in
    if matches then
        -- pass in as little as possible so lazy works as well as possible
        Html.Lazy.lazy3 row humanise tableConfig torrent

    else
        text ""


row : Model.Config.Humanise -> Model.Table.Config -> Torrent -> Html Msg
row humanise tableConfig torrent =
    let
        {-
           _ =
               Debug.log "rendering:" torrent
        -}
        visibleColumns =
            List.filter .visible tableConfig.columns

        cell =
            \column ->
                View.Table.cell
                    tableConfig
                    column.attribute
                    (cellContent
                        humanise
                        torrent
                        (Model.Attribute.unwrap column.attribute)
                    )
    in
    tr [] (List.map cell visibleColumns)


cellContent : Model.Config.Humanise -> Torrent -> Model.Torrent.Attribute -> Html Msg
cellContent humanise torrent attribute =
    case attribute of
        Model.Torrent.Status ->
            torrentStatusCell torrent

        Model.Torrent.DonePercent ->
            donePercentCell torrent

        _ ->
            attributeAccessor humanise torrent attribute


torrentStatusCell : Torrent -> Html Msg
torrentStatusCell torrent =
    case torrent.status of
        Model.Torrent.Seeding ->
            torrentStatusIcon "seeding" "fa-arrow-up"

        Model.Torrent.Errored ->
            torrentStatusIcon "errored" "fa-times"

        Model.Torrent.Downloading ->
            torrentStatusIcon "downloading" "fa-arrow-down"

        Model.Torrent.Paused ->
            torrentStatusIcon "paused" "fa-pause"

        Model.Torrent.Stopped ->
            torrentStatusIcon "stopped" ""

        Model.Torrent.Hashing ->
            torrentStatusIcon "hashing" "fa-sync"


torrentStatusIcon : String -> String -> Html Msg
torrentStatusIcon kls icon =
    span [ class ("torrent-status " ++ kls ++ " fa-stack") ]
        [ i [ class "fas fa-square fa-stack-2x" ] []
        , i [ class ("fas " ++ icon ++ " fa-inverse fa-stack-1x") ] []
        ]


donePercentCell : Torrent -> Html Msg
donePercentCell torrent =
    let
        dp =
            if torrent.donePercent == 100 then
                0

            else
                1
    in
    div [ class "progress-container" ]
        [ progress
            [ Html.Attributes.max "100"
            , Html.Attributes.value <| Round.round 0 torrent.donePercent
            ]
            []
        , span []
            [ text (Round.round dp torrent.donePercent ++ "%") ]
        ]



-- convert a Torrent Attribute into content for a cell in this table


attributeAccessor : Model.Config.Humanise -> Torrent -> Model.Torrent.Attribute -> Html Msg
attributeAccessor humanise torrent attribute =
    let
        -- convert 0 speeds to Nothing
        humanByteSpeed =
            \bytes ->
                case bytes of
                    0 ->
                        Nothing

                    r ->
                        Just <| Utils.Filesize.formatWith humanise.speed r ++ "/s"
    in
    case attribute of
        Model.Torrent.Status ->
            -- has an icon
            text ""

        Model.Torrent.Name ->
            text <| torrent.name

        Model.Torrent.Size ->
            text <| Utils.Filesize.formatWith humanise.size torrent.size

        Model.Torrent.CreationTime ->
            nonZeroLocalTimeNode torrent.creationTime

        Model.Torrent.StartedTime ->
            nonZeroLocalTimeNode torrent.startedTime

        Model.Torrent.FinishedTime ->
            nonZeroLocalTimeNode torrent.finishedTime

        Model.Torrent.DownloadedBytes ->
            text <| Utils.Filesize.formatWith humanise.size torrent.downloadedBytes

        Model.Torrent.DownloadRate ->
            text <|
                Maybe.withDefault "" (humanByteSpeed torrent.downloadRate)

        Model.Torrent.UploadedBytes ->
            text <| Utils.Filesize.formatWith humanise.size torrent.uploadedBytes

        Model.Torrent.UploadRate ->
            text <|
                Maybe.withDefault "" (humanByteSpeed torrent.uploadRate)

        Model.Torrent.Ratio ->
            -- ratio can have a couple of special cases
            text <|
                case ( isInfinite torrent.ratio, isNaN torrent.ratio ) of
                    ( False, False ) ->
                        Round.round 3 torrent.ratio

                    ( _, True ) ->
                        "—"

                    ( True, _ ) ->
                        "∞"

        Model.Torrent.Seeders ->
            text <|
                String.fromInt torrent.seedersConnected
                    ++ " ("
                    ++ String.fromInt torrent.seedersTotal
                    ++ ")"

        Model.Torrent.SeedersConnected ->
            text <| String.fromInt torrent.seedersConnected

        Model.Torrent.SeedersTotal ->
            text <| String.fromInt torrent.seedersTotal

        Model.Torrent.Peers ->
            text <|
                String.fromInt torrent.peersConnected
                    ++ " ("
                    ++ String.fromInt torrent.peersTotal
                    ++ ")"

        Model.Torrent.PeersConnected ->
            text <| String.fromInt torrent.peersConnected

        Model.Torrent.PeersTotal ->
            text <| String.fromInt torrent.peersTotal

        Model.Torrent.Label ->
            text <| torrent.label

        Model.Torrent.DonePercent ->
            text <| String.fromFloat torrent.donePercent


nonZeroLocalTimeNode : Int -> Html Msg
nonZeroLocalTimeNode time =
    if time == 0 then
        text ""

    else
        View.Utils.LocalTimeNode.view time
