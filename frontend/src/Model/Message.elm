module Model.Message exposing (..)

import Time


type alias Message =
    { summary : Maybe String
    , detail : Maybe String
    , severity : Severity
    , time : Time.Posix
    }


type Severity
    = Info
    | Warning
    | Error


addMessage : Message -> List Message -> List Message
addMessage newMessage messages =
    addMessages messages [ newMessage ]


addMessages : List Message -> List Message -> List Message
addMessages newMessages messages =
    {- this feels like the args are the wrong way around, but having them
       this way ends up with newer messages at the end of model.messages *shrug*
    -}
    List.append newMessages messages
