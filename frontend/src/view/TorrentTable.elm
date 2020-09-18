module View.TorrentTable exposing (..)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onMouseDown, onMouseUp)
import Html.Keyed as Keyed
import Html.Lazy
import Model exposing (..)
import Model.Utils.TorrentAttribute
import Utils.Filesize


view : Model -> Html Msg
view model =
    table [ onMouseUp MouseUp ]
        (List.concat
            [ [ header model ]
            , [ body model ]
            ]
        )


header : Model -> Html Msg
header model =
    let
        visibleOrder =
            List.filter (isVisible model.config.visibleTorrentAttributes)
                model.config.torrentAttributeOrder
    in
    thead []
        [ tr []
            (List.map (headerCell model) visibleOrder)
        ]


headerCell : Model -> TorrentAttribute -> Html Msg
headerCell model attribute =
    let
        attrString =
            Model.Utils.TorrentAttribute.attributeToTableHeaderString
                attribute
    in
    th (headerCellAttributes model attribute)
        [ span (headerCellSpanAttributes model attribute)
            [ text <| attrString ]
        , div
            [ onMouseDown (MouseDown attribute Right)
            ]
            []
        ]


headerCellAttributes : Model -> TorrentAttribute -> List (Attribute Msg)
headerCellAttributes model attribute =
    List.filterMap identity <|
        [ cellTextAlign attribute
        , headerCellSortClass model.config attribute
        ]


headerCellSpanAttributes : Model -> TorrentAttribute -> List (Attribute Msg)
headerCellSpanAttributes model attribute =
    [ onClick (SetSortBy attribute)
    ]


headerCellWidth : Model -> TorrentAttribute -> Attribute Msg
headerCellWidth model attribute =
    let
        key =
            Model.Utils.TorrentAttribute.attributeToKey attribute

        width =
            case Dict.get key model.columnWidths of
                Just x ->
                    x

                Nothing ->
                    50
    in
    style "width" (String.fromFloat width ++ "px")


headerCellSortClass : Config -> TorrentAttribute -> Maybe (Attribute Msg)
headerCellSortClass config attribute =
    let
        (SortBy currentSortAttribute currentSortDirection) =
            config.sortBy
    in
    if currentSortAttribute == attribute then
        case currentSortDirection of
            Asc ->
                Just <| class "sorted ascending"

            Desc ->
                Just <| class "sorted descending"

    else
        Nothing


body : Model -> Html Msg
body model =
    Keyed.node "tbody" [] <|
        List.filterMap
            identity
            (List.map (keyedRow model) model.sortedTorrents)


keyedRow : Model -> String -> Maybe ( String, Html Msg )
keyedRow model hash =
    case Dict.get hash model.torrentsByHash of
        Just torrent ->
            Just
                ( torrent.hash
                , lazyRow model model.config model.filesizeSettings torrent
                )

        Nothing ->
            Nothing


lazyRow : Model -> Config -> Utils.Filesize.Settings -> Torrent -> Html Msg
lazyRow model config filesizeSettings torrent =
    -- just pass in what the row actually needs so lazy can look at
    -- as little as possible. this will help when some config changes,
    -- but not the config related to rendering the row.
    Html.Lazy.lazy5 row
        model
        config.visibleTorrentAttributes
        config.torrentAttributeOrder
        filesizeSettings
        torrent


row : Model -> List TorrentAttribute -> List TorrentAttribute -> Utils.Filesize.Settings -> Torrent -> Html Msg
row model visibleTorrentAttributes torrentAttributeOrder filesizeSettings torrent =
    let
        x =
            1

        -- Debug.log "rendering:" torrent
        visibleOrder =
            List.filter (isVisible visibleTorrentAttributes)
                torrentAttributeOrder
    in
    tr
        []
        (List.map (cell model filesizeSettings torrent) visibleOrder)


isVisible : List TorrentAttribute -> TorrentAttribute -> Bool
isVisible visibleTorrentAttributes attribute =
    List.member attribute visibleTorrentAttributes


cell : Model -> Utils.Filesize.Settings -> Torrent -> TorrentAttribute -> Html Msg
cell model filesizeSettings torrent attribute =
    td (cellAttributes attribute)
        [ div (cellDivAttributes model attribute)
            [ cellContent filesizeSettings torrent attribute
            ]
        ]


cellDivAttributes : Model -> TorrentAttribute -> List (Attribute Msg)
cellDivAttributes model attribute =
    [ headerCellWidth model attribute ]


cellContent : Utils.Filesize.Settings -> Torrent -> TorrentAttribute -> Html Msg
cellContent filesizeSettings torrent attribute =
    if attribute == DonePercent then
        donePercentCell torrent

    else
        text <|
            Model.Utils.TorrentAttribute.attributeAccessor
                filesizeSettings
                torrent
                attribute


donePercentCell : Torrent -> Html Msg
donePercentCell torrent =
    progress
        [ Html.Attributes.max "100"
        , Html.Attributes.value <| String.fromFloat torrent.donePercent
        ]
        [ text (String.fromFloat torrent.donePercent ++ "%") ]


cellAttributes : TorrentAttribute -> List (Attribute Msg)
cellAttributes attribute =
    List.filterMap identity <|
        [ cellTextAlign attribute
        ]


cellTextAlign : TorrentAttribute -> Maybe (Attribute msg)
cellTextAlign attribute =
    case Model.Utils.TorrentAttribute.textAlignment attribute of
        Just str ->
            Just <| class "text-right"

        Nothing ->
            Nothing
