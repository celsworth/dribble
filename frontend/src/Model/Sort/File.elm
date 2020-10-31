module Model.Sort.File exposing (sort)

import List.Extra
import Model.File
    exposing
        ( Attribute(..)
        , File
        , Sort(..)
        )
import Model.Sort exposing (SortDirection(..))


sort : Model.File.Sort -> List File -> List String
sort sortBy files =
    let
        comparators =
            [ comparator sortBy ]
    in
    List.map .path <|
        List.foldl List.Extra.stableSortWith files comparators


comparator : Model.File.Sort -> (File -> File -> Order)
comparator sortBy =
    let
        (SortBy attribute direction) =
            sortBy
    in
    case attribute of
        Path ->
            \a b -> maybeReverse direction <| cmp a b .path

        Size ->
            \a b -> maybeReverse direction <| cmp a b .size

        DonePercent ->
            \a b -> maybeReverse direction <| cmp a b .donePercent


cmp : File -> File -> (File -> comparable) -> Order
cmp a b method =
    let
        a1 =
            method a

        b1 =
            method b
    in
    if a1 == b1 then
        EQ

    else if a1 > b1 then
        GT

    else
        LT


maybeReverse : SortDirection -> Order -> Order
maybeReverse direction order =
    case direction of
        Asc ->
            order

        Desc ->
            case order of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT



-- MISC


infiniteToFloat : Float -> Float
infiniteToFloat ratio =
    case ( isNaN ratio, isInfinite ratio ) of
        ( True, _ ) ->
            -- keep NaN at the bottom
            -1

        ( _, True ) ->
            -- keep infinite at the top
            99999999999

        ( _, _ ) ->
            ratio
