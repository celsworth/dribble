module View.TorrentTable exposing (..)

import Dict
import Filesize
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy3)
import Model exposing (..)
import View.Utils.TorrentAttributeMethods


view : Model -> Html msg
view model =
    table []
        (List.concat
            [ [ tableHeader model.config ]
            , [ tableBody model ]
            ]
        )


tableHeader : Config -> Html msg
tableHeader config =
    let
        visibleOrder =
            List.filter (isVisible config.visibleTorrentAttributes)
                config.torrentAttributeOrder
    in
    thead [] [ tr [] (List.map headerCell visibleOrder) ]


headerCell : TorrentAttribute -> Html msg
headerCell attribute =
    th []
        [ text <|
            View.Utils.TorrentAttributeMethods.attributeToTableHeaderString
                attribute
        ]


tableBody : Model -> Html msg
tableBody model =
    Keyed.node "tbody" [] <|
        List.filterMap
            identity
            (List.map (keyedtableRow model) model.sortedTorrents)


keyedtableRow : Model -> String -> Maybe ( String, Html msg )
keyedtableRow model hash =
    case Dict.get hash model.torrentsByHash of
        Just torrent ->
            Just
                ( torrent.hash
                , lazy3 tableRow model.config model.filesizeSettings torrent
                )

        Nothing ->
            Nothing


tableRow : Config -> Filesize.Settings -> Torrent -> Html msg
tableRow config filesizeSettings torrent =
    let
        x =
            1

        -- Debug.log "rendering:" torrent
        cell =
            tableCell filesizeSettings torrent

        visibleOrder =
            List.filter (isVisible config.visibleTorrentAttributes)
                config.torrentAttributeOrder
    in
    tr
        []
        (List.map cell visibleOrder)


isVisible : List TorrentAttribute -> TorrentAttribute -> Bool
isVisible visibleTorrentAttributes attribute =
    List.member attribute visibleTorrentAttributes


tableCell : Filesize.Settings -> Torrent -> TorrentAttribute -> Html msg
tableCell filesizeSettings torrent attribute =
    let
        content =
            View.Utils.TorrentAttributeMethods.attributeAccessor
                filesizeSettings
                torrent
                attribute
    in
    td (tableCellAttributes attribute)
        [ text content
        ]


tableCellAttributes : TorrentAttribute -> List (Attribute msg)
tableCellAttributes attribute =
    List.filterMap identity <|
        [ tableCellTextAlign attribute
        ]


tableCellTextAlign : TorrentAttribute -> Maybe (Attribute msg)
tableCellTextAlign attribute =
    case View.Utils.TorrentAttributeMethods.textAlignment attribute of
        Just str ->
            Just <| style "text-align" str

        Nothing ->
            Nothing
