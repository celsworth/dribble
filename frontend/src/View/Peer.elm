module View.Peer exposing (attributeAccessor, attributeTextAlignment)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Peer exposing (Peer)


attributeAccessor : Peer -> Model.Peer.Attribute -> Html Msg
attributeAccessor peer attribute =
    text ""


attributeTextAlignment : Model.Peer.Attribute -> Maybe String
attributeTextAlignment attribute =
    case attribute of
        _ ->
            Nothing
