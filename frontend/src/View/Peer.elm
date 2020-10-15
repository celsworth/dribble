module View.Peer exposing (attributeAccessor)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Peer exposing (Peer)
import Utils.Filesize


attributeAccessor : Peer -> Model.Peer.Attribute -> Html Msg
attributeAccessor peer attribute =
    text ""
