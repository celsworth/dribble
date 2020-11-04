module View.GroupLists exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onMouseLeave)
import Html.Lazy
import Model exposing (..)
import Model.GroupLists exposing (Group, GroupLists)
import Model.Torrent
import View.Utils.TorrentStatusIcon


view : Model -> Html Msg
view model =
    Html.Lazy.lazy groupListsView model.groupLists


groupListsView : GroupLists -> Html Msg
groupListsView groupLists =
    div []
        [ groupListWithIcon "Status" groupLists.byStatus
        , groupList "Labels" groupLists.byLabel
        , groupListWithFavicon "Trackers" groupLists.byTracker
        ]


groupList : String -> Group -> Html Msg
groupList header group =
    div [ class "group-list" ]
        [ p [ class "header" ] [ text header ]
        , ul [] <| List.map listItem (Dict.toList group)
        ]


listItem : ( String, Int ) -> Html Msg
listItem ( label, count ) =
    let
        nonEmptyLabel =
            if String.isEmpty label then
                "(No Label)"

            else
                label
    in
    li []
        [ span [ class "label" ] [ text nonEmptyLabel ]
        , span [] [ text <| String.fromInt count ]
        ]


groupListWithIcon : String -> Group -> Html Msg
groupListWithIcon header group =
    div [ class "group-list" ]
        [ p [ class "header" ] [ text header ]
        , ul [] <| List.map listItemWithIcon (Dict.toList group)
        ]


listItemWithIcon : ( String, Int ) -> Html Msg
listItemWithIcon ( label, count ) =
    li []
        [ span [ class "label" ]
            [ icon label
            , text label
            ]
        , span [] [ text <| String.fromInt count ]
        ]


icon : String -> Html Msg
icon label =
    Maybe.withDefault (text "") <|
        Maybe.map
            View.Utils.TorrentStatusIcon.view
            (Model.Torrent.stringToStatus label)


groupListWithFavicon : String -> Group -> Html Msg
groupListWithFavicon header group =
    div [ class "group-list" ]
        [ p [ class "header" ] [ text header ]
        , ul [] <| List.map listItemWithFavicon (Dict.toList group)
        ]


listItemWithFavicon : ( String, Int ) -> Html Msg
listItemWithFavicon ( label, count ) =
    li []
        [ span [ class "label" ]
            [ trackerFavicon label
            , text label
            ]
        , span [] [ text <| String.fromInt count ]
        ]


trackerFavicon : String -> Html Msg
trackerFavicon domain =
    img
        [ style "width" "16px"
        , style "height" "16px"
        , src <| "/proxy/" ++ domain ++ "/favicon.ico"
        ]
        []
