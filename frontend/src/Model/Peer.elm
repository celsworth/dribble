module Model.Peer exposing (..)

-- temporary placeholder


type Attribute
    = Status
    | Address


type alias Peer =
    { status : String
    , ip : Int
    }



-- ATTRIBUTE ACCCESSORS ETC


attributeToKey : Attribute -> String
attributeToKey attribute =
    case attribute of
        Status ->
            "status"

        Address ->
            "address"


keyToAttribute : String -> Maybe Attribute
keyToAttribute str =
    case str of
        "status" ->
            Just Status

        "address" ->
            Just Address

        _ ->
            Nothing


attributeToTableHeaderId : Attribute -> String
attributeToTableHeaderId attribute =
    "th-peerAttribute-" ++ attributeToKey attribute


attributeToTableHeaderString : Attribute -> String
attributeToTableHeaderString attribute =
    case attribute of
        _ ->
            attributeToString attribute


attributeToString : Attribute -> String
attributeToString attribute =
    case attribute of
        Status ->
            "Status"

        Address ->
            "Address"


attributeTextAlignment : Attribute -> Maybe String
attributeTextAlignment attribute =
    case attribute of
        _ ->
            Nothing
