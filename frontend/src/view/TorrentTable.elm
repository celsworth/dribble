module View.TorrentTable exposing (..)

import Filesize
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy3)
import Model exposing (..)
import Torrent
import View.Utils.TorrentAttributeMethods


view : Model -> Html msg
view model =
    table []
        (List.concat
            [ [ tableHeader ]
            , [ tableBody model ]
            ]
        )


tableHeader : Html msg
tableHeader =
    thead []
        [ tr []
            [ th [] [ text "Name" ]
            , th [] [ text "Size" ]
            , th [] [ text "Created" ]
            , th [] [ text "Started" ]
            , th [] [ text "Finished" ]
            , th [] [ text "Uploaded" ]
            , th [] [ text "Up B/s" ]
            , th [] [ text "Downloaded" ]
            , th [] [ text "Down B/s" ]
            ]
        ]


tableBody : Model -> Html msg
tableBody model =
    Keyed.node
        "tbody"
        []
        (List.map (keyedtableRow model) model.torrents.sorted)


tableBody2 : Model -> Html msg
tableBody2 model =
    let
        visible =
            model.config.visibleTorrentAttributes
    in
    p [] []


keyedtableRow : Model -> Torrent -> ( String, Html msg )
keyedtableRow model torrent =
    ( torrent.hash, lazy3 tableRow model.config model.filesizeSettings torrent )


tableRow : Config -> Filesize.Settings -> Torrent -> Html msg
tableRow config filesizeSettings torrent =
    let
        x =
            Debug.log "rendering:" torrent

        cell =
            tableCell filesizeSettings torrent
    in
    -- TODO: this should use torrentAttributeOrder and filter by visible?
    tr
        []
        (List.map cell config.visibleTorrentAttributes)


tableCell : Filesize.Settings -> Torrent -> TorrentAttribute -> Html msg
tableCell filesizeSettings torrent attribute =
    let
        content =
            Torrent.attributeAccessor filesizeSettings torrent attribute
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
