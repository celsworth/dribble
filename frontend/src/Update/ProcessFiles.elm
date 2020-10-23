module Update.ProcessFiles exposing (update)

import Dict
import Model exposing (..)
import Model.File exposing (File)


update : List File -> Model -> ( Model, Cmd Msg )
update files model =
    let
        byKey =
            filesByKey model files
    in
    model
        |> setSortedFiles (sortedFiles byKey model.config.fileTable.sortBy)
        |> setKeyedFiles byKey
        |> noCmd


sortedFiles : Model.File.FilesByKey -> Model.File.Sort -> List String
sortedFiles byKey sortBy =
    --Model.Sort.File.sort sortBy (Dict.values byKey)
    List.map .path (Dict.values byKey)


filesByKey : Model -> List File -> Model.File.FilesByKey
filesByKey model fileList =
    let
        newDict =
            Dict.fromList <| List.map (\f -> ( f.path, f )) fileList
    in
    Dict.union newDict model.keyedFiles
