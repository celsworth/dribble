module View.Torrent exposing (attributeAccessor, attributeTextAlignment)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Config
import Model.Torrent exposing (Torrent)
import Round
import Utils.Filesize
import View.Utils.LocalTimeNode


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

        Model.Torrent.FileCount ->
            text <| String.fromInt torrent.fileCount

        Model.Torrent.CreationTime ->
            View.Utils.LocalTimeNode.nonZeroView torrent.creationTime

        Model.Torrent.AddedTime ->
            View.Utils.LocalTimeNode.nonZeroView torrent.addedTime

        Model.Torrent.StartedTime ->
            View.Utils.LocalTimeNode.nonZeroView torrent.startedTime

        Model.Torrent.FinishedTime ->
            View.Utils.LocalTimeNode.nonZeroView torrent.finishedTime

        Model.Torrent.DownloadedBytes ->
            text <| Utils.Filesize.formatWith humanise.size torrent.downloadedBytes

        Model.Torrent.DownloadRate ->
            text <|
                Maybe.withDefault "" (humanByteSpeed torrent.downloadRate)

        Model.Torrent.UploadedBytes ->
            text <| Utils.Filesize.formatWith humanise.size torrent.uploadedBytes

        Model.Torrent.SkippedBytes ->
            text <| Utils.Filesize.formatWith humanise.size torrent.skippedBytes

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

        Model.Torrent.Priority ->
            text <| Model.Torrent.priorityToString torrent.priority

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


attributeTextAlignment : Model.Torrent.Attribute -> Maybe String
attributeTextAlignment attribute =
    case attribute of
        Model.Torrent.Size ->
            Just "text-right"

        Model.Torrent.FileCount ->
            Just "text-right"

        Model.Torrent.DownloadedBytes ->
            Just "text-right"

        Model.Torrent.DownloadRate ->
            Just "text-right"

        Model.Torrent.UploadedBytes ->
            Just "text-right"

        Model.Torrent.UploadRate ->
            Just "text-right"

        Model.Torrent.SkippedBytes ->
            Just "text-right"

        Model.Torrent.CreationTime ->
            Just "text-right"

        Model.Torrent.AddedTime ->
            Just "text-right"

        Model.Torrent.StartedTime ->
            Just "text-right"

        Model.Torrent.FinishedTime ->
            Just "text-right"

        Model.Torrent.Ratio ->
            Just "text-right"

        Model.Torrent.Seeders ->
            Just "text-right"

        Model.Torrent.SeedersConnected ->
            Just "text-right"

        Model.Torrent.SeedersTotal ->
            Just "text-right"

        Model.Torrent.Peers ->
            Just "text-right"

        Model.Torrent.PeersConnected ->
            Just "text-right"

        Model.Torrent.PeersTotal ->
            Just "text-right"

        _ ->
            Nothing
