module Update.SetSelectedTorrent exposing (update)

import Model exposing (..)


update : String -> Model -> ( Model, Cmd Msg )
update hash model =
    model
        |> setSelectedTorrentHash hash
        |> clearFiles
        |> noCmd
