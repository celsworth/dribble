module Update.TorrentFilterChanged exposing (update)

import Model exposing (..)
import Model.Config
import Model.TorrentFilter


update : String -> Model -> ( Model, Cmd Msg )
update value model =
    let
        newFilterConfig =
            model.config.filter |> Model.TorrentFilter.setFilter value

        newConfig =
            model.config |> Model.Config.setFilter newFilterConfig

        -- split into another Update?
        newFilter =
            Model.TorrentFilter.filterFromConfig newFilterConfig
    in
    model
        |> setConfig newConfig
        |> setTorrentFilter newFilter
        |> noCmd
