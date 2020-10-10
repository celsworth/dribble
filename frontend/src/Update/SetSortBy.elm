module Update.SetSortBy exposing (update)

import Dict
import Model exposing (..)
import Model.Attribute
import Model.Config
import Model.Sort exposing (SortDirection(..))
import Model.Sort.Torrent
import Model.Torrent


update : Model.Attribute.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    case attribute of
        Model.Attribute.TorrentAttribute a ->
            model |> sortTorrents a

        Model.Attribute.PeerAttribute _ ->
            Debug.todo "support peer sorting"


sortTorrents : Model.Torrent.Attribute -> Model -> ( Model, Cmd Msg )
sortTorrents attribute model =
    let
        config =
            model.config

        (Model.Torrent.SortBy currentAttr currentDirection) =
            config.sortBy

        currentSortMatchesAttr =
            currentAttr == attribute

        newSort =
            if currentSortMatchesAttr then
                case currentDirection of
                    Asc ->
                        Model.Torrent.SortBy attribute Desc

                    Desc ->
                        Model.Torrent.SortBy attribute Asc

            else
                Model.Torrent.SortBy attribute currentDirection

        newSortedTorrents =
            Model.Sort.Torrent.sort newSort (Dict.values model.torrentsByHash)

        newConfig =
            config |> Model.Config.setSortBy newSort
    in
    model
        |> setConfig newConfig
        |> setSortedTorrents newSortedTorrents
        |> noCmd



{-

   update : Model.Attribute.Attribute -> Model -> ( Model, Cmd Msg )
   update attribute model =
       let
           newConfig =
               model.config |> updateConfig attribute

           (Model.Attribute.SortBy sortByAttribute sortByDir) =
               newConfig.sortBy
       in
       model
           |> setConfig newConfig
           |> applyNewSort sortByAttribute sortByDir
           |> noCmd


   applyNewSort : Model.Attribute.Attribute -> Model.Attribute.SortDirection -> Model -> Model
   applyNewSort sortByAttribute sortByDir model =
       case sortByAttribute of
           Model.Attribute.TorrentAttribute torrentAttribute ->
               model
                   |> setSortedTorrents
                       (Model.Sort.Torrent.sort
                           torrentAttribute
                           sortByDir
                           (Dict.values model.torrentsByHash)
                       )

           Model.Attribute.PeerAttribute peerAttribute ->
               Debug.todo "TODO: peer sorting"


   updateConfig : Model.Attribute.Attribute -> Config -> Config
   updateConfig attr config =
       let
           (Model.Attribute.SortBy currentAttr currentDirection) =
               config.sortBy

           currentSortMatchesAttr =
               currentAttr == attr

           newSort =
               if currentSortMatchesAttr then
                   case currentDirection of
                       Model.Attribute.Asc ->
                           Model.Attribute.SortBy attr Model.Attribute.Desc

                       Model.Attribute.Desc ->
                           Model.Attribute.SortBy attr Model.Attribute.Asc

               else
                   Model.Attribute.SortBy attr currentDirection
       in
       config |> Model.Config.setSortBy newSort

-}
