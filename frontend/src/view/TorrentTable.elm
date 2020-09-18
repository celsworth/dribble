module View.TorrentTable exposing (..)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onMouseDown)
import Html.Keyed as Keyed
import Html.Lazy
import Model exposing (..)
import Model.Utils.TorrentAttribute
import Utils.Filesize


view : Model -> Html Msg
view model =
    table []
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
            (List.map (headerCell model.config) visibleOrder)
        ]


headerCell : Config -> TorrentAttribute -> Html Msg
headerCell config attribute =
    let
        attrString =
            Model.Utils.TorrentAttribute.attributeToTableHeaderString
                attribute
    in
    th (headerCellAttributes config attribute)
        [ text <| attrString ]


headerCellAttributes : Config -> TorrentAttribute -> List (Attribute Msg)
headerCellAttributes config attribute =
    List.filterMap identity <|
        [ cellTextAlign attribute
        , headerCellSortClass config attribute
        , Just (onClick (SetSortBy attribute))
        ]


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


body : Model -> Html msg
body model =
    Keyed.node "tbody" [] <|
        List.filterMap
            identity
            (List.map (keyedRow model) model.sortedTorrents)


keyedRow : Model -> String -> Maybe ( String, Html msg )
keyedRow model hash =
    case Dict.get hash model.torrentsByHash of
        Just torrent ->
            Just
                ( torrent.hash
                , lazyRow model.config model.filesizeSettings torrent
                )

        Nothing ->
            Nothing


lazyRow : Config -> Utils.Filesize.Settings -> Torrent -> Html msg
lazyRow config filesizeSettings torrent =
    -- just pass in what the row actually needs so lazy can look at
    -- as little as possible. this will help when some config changes,
    -- but not the config related to rendering the row.
    Html.Lazy.lazy4 row
        config.visibleTorrentAttributes
        config.torrentAttributeOrder
        filesizeSettings
        torrent


row : List TorrentAttribute -> List TorrentAttribute -> Utils.Filesize.Settings -> Torrent -> Html msg
row visibleTorrentAttributes torrentAttributeOrder filesizeSettings torrent =
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
        (List.map (cell filesizeSettings torrent) visibleOrder)


isVisible : List TorrentAttribute -> TorrentAttribute -> Bool
isVisible visibleTorrentAttributes attribute =
    List.member attribute visibleTorrentAttributes


cell : Utils.Filesize.Settings -> Torrent -> TorrentAttribute -> Html msg
cell filesizeSettings torrent attribute =
    td (cellAttributes attribute)
        [ cellContent filesizeSettings torrent attribute
        ]


cellContent : Utils.Filesize.Settings -> Torrent -> TorrentAttribute -> Html msg
cellContent filesizeSettings torrent attribute =
    if attribute == DonePercent then
        donePercentCell torrent

    else
        text <|
            Model.Utils.TorrentAttribute.attributeAccessor
                filesizeSettings
                torrent
                attribute


donePercentCell : Torrent -> Html msg
donePercentCell torrent =
    progress
        [ Html.Attributes.max "100"
        , Html.Attributes.value <| String.fromFloat torrent.donePercent
        ]
        [ text (String.fromFloat torrent.donePercent ++ "%") ]


cellAttributes : TorrentAttribute -> List (Attribute msg)
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
