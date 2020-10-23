module View.GroupLists exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)


view : Model -> Html Msg
view model =
    if model.groupListsVisible then
        div [ class "group-lists" ]
            [ text "test" ]

    else
        text ""
