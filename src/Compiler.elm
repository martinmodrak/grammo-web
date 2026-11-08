port module Compiler exposing
    ( CompileResult(..)
    , Diagnostic
    , compile
    , compiled
    , decoder
    , fromValue
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


port compile : String -> Cmd msg


port compiled : (Encode.Value -> msg) -> Sub msg


type alias Diagnostic =
    String


type CompileResult
    = Compiled { code : String, warnings : List Diagnostic }
    | Failed (List Diagnostic)


{-| Decodes `{ error : string | null, code : string | null }`.

When both are present, Grammo compiled but the generated Stan is invalid, so
the code is kept and the error is shown as a warning.

-}
decoder : Decoder CompileResult
decoder =
    Decode.map2 fromFields
        (Decode.field "error" (Decode.nullable Decode.string))
        (Decode.field "code" (Decode.nullable Decode.string))
        |> Decode.andThen identity


fromFields : Maybe String -> Maybe String -> Decoder CompileResult
fromFields error code =
    case ( code, error ) of
        ( Just stan, Nothing ) ->
            Decode.succeed (Compiled { code = stan, warnings = [] })

        ( Just stan, Just warning ) ->
            Decode.succeed (Compiled { code = stan, warnings = [ warning ] })

        ( Nothing, Just message ) ->
            Decode.succeed (Failed [ message ])

        ( Nothing, Nothing ) ->
            Decode.fail "Expected at least one of `error` and `code` to be set"


{-| Turns whatever arrived through the port into a result. A payload that does
not match the contract is reported to the user as a failure.
-}
fromValue : Encode.Value -> CompileResult
fromValue value =
    case Decode.decodeValue decoder value of
        Ok result ->
            result

        Err error ->
            Failed [ "Unexpected response from the compiler:\n" ++ Decode.errorToString error ]
