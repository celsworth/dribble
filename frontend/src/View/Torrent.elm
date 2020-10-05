module View.Torrent exposing (..)

import Html exposing (Html, text)
import Model exposing (..)
import Model.Config
import Model.Torrent exposing (..)
import Utils.Filesize
import View.Utils.LocalTimeNode


attributeToTableHeaderId : Attribute -> String
attributeToTableHeaderId attribute =
    "th-ta-" ++ attributeToKey attribute


attributeAccessor : Model.Config.Humanise -> Torrent -> Attribute -> Html Msg
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
        Status ->
            -- has an icon
            text ""

        Name ->
            text <| torrent.name

        Size ->
            text <| Utils.Filesize.formatWith humanise.size torrent.size

        CreationTime ->
            nonZeroLocalTimeNode torrent.creationTime

        StartedTime ->
            nonZeroLocalTimeNode torrent.startedTime

        FinishedTime ->
            nonZeroLocalTimeNode torrent.finishedTime

        DownloadedBytes ->
            text <| Utils.Filesize.formatWith humanise.size torrent.downloadedBytes

        DownloadRate ->
            text <|
                Maybe.withDefault "" (humanByteSpeed torrent.downloadRate)

        UploadedBytes ->
            text <| Utils.Filesize.formatWith humanise.size torrent.uploadedBytes

        UploadRate ->
            text <|
                Maybe.withDefault "" (humanByteSpeed torrent.uploadRate)

        Seeders ->
            text <|
                String.fromInt torrent.seedersConnected
                    ++ " ("
                    ++ String.fromInt torrent.seedersTotal
                    ++ ")"

        SeedersConnected ->
            text <| String.fromInt torrent.seedersConnected

        SeedersTotal ->
            text <| String.fromInt torrent.seedersTotal

        Peers ->
            text <|
                String.fromInt torrent.peersConnected
                    ++ " ("
                    ++ String.fromInt torrent.peersTotal
                    ++ ")"

        PeersConnected ->
            text <| String.fromInt torrent.peersConnected

        PeersTotal ->
            text <| String.fromInt torrent.peersTotal

        Label ->
            text <| torrent.label

        DonePercent ->
            text <| String.fromFloat torrent.donePercent


nonZeroLocalTimeNode : Int -> Html Msg
nonZeroLocalTimeNode time =
    if time == 0 then
        text ""

    else
        View.Utils.LocalTimeNode.view time


textAlignment : Attribute -> Maybe String
textAlignment attribute =
    case attribute of
        Size ->
            Just "text-right"

        DownloadedBytes ->
            Just "text-right"

        DownloadRate ->
            Just "text-right"

        UploadedBytes ->
            Just "text-right"

        UploadRate ->
            Just "text-right"

        Seeders ->
            Just "text-right"

        SeedersConnected ->
            Just "text-right"

        SeedersTotal ->
            Just "text-right"

        Peers ->
            Just "text-right"

        PeersConnected ->
            Just "text-right"

        PeersTotal ->
            Just "text-right"

        _ ->
            Nothing


attributeToTableHeaderString : Attribute -> String
attributeToTableHeaderString attribute =
    case attribute of
        Status ->
            {- force #ta-ta-torrentStatus .size .content to
               have height so it can be clicked on
            -}
            "\u{00A0}"

        CreationTime ->
            "Created"

        StartedTime ->
            "Started"

        FinishedTime ->
            "Finished"

        DownloadRate ->
            "Down"

        UploadRate ->
            "Up"

        _ ->
            attributeToString attribute



-- return a human readable version of an Attribute definition.
-- this is used in HTML when there is no other specific method available
-- (eg, we have one for table headers which has shorter strings for some)


attributeToString : Attribute -> String
attributeToString attribute =
    case attribute of
        Status ->
            "Status"

        Name ->
            "Name"

        Size ->
            "Size"

        CreationTime ->
            "Creation Time"

        StartedTime ->
            "Started Time"

        FinishedTime ->
            "Finished Time"

        DownloadedBytes ->
            "Downloaded"

        DownloadRate ->
            "Download Rate"

        UploadedBytes ->
            "Uploaded"

        UploadRate ->
            "Upload Rate"

        SeedersConnected ->
            "Seeders Connected"

        Seeders ->
            "Seeders"

        SeedersTotal ->
            "Seeders Total"

        Peers ->
            "Peers"

        PeersConnected ->
            "Peers Connected"

        PeersTotal ->
            "Peers Total"

        Label ->
            "Label"

        DonePercent ->
            "Done"
