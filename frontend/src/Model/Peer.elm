module Model.Peer exposing (..)

-- temporary placeholder


type Attribute
    = Status
    | Address


type alias Peer =
    { status : String
    , ip : Int
    }
