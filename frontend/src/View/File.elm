module View.File exposing (attributeAccessor, attributeTextAlignment)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Config
import Model.File exposing (File)
import Utils.Filesize


attributeAccessor : Model.Config.Humanise -> File -> Model.File.Attribute -> Html Msg
attributeAccessor humanise file attribute =
    case attribute of
        Model.File.Path ->
            text <| file.path

        Model.File.Size ->
            text <| Utils.Filesize.formatWith humanise.size file.size

        Model.File.DonePercent ->
            text <| String.fromFloat file.donePercent


attributeTextAlignment : Model.File.Attribute -> Maybe String
attributeTextAlignment attribute =
    case attribute of
        Model.File.Size ->
            Just "text-right"

        _ ->
            Nothing
