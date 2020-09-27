module Model.Message exposing (..)

{- info/warning/error messages to display -}


type alias Message =
    { message : String
    , severity : Severity
    }


type Severity
    = Info
    | Warning
    | Error


addMessage : Message -> List Message -> List Message
addMessage newMessage messages =
    List.append messages [ newMessage ]
