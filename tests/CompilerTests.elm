module CompilerTests exposing (suite)

import Compiler exposing (CompileResult(..))
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


{-| The start of the real output for the valid program in Examples.md.
-}
realCode : String
realCode =
    """{ Ast.data =
  [{ Data.name = "df";
     type_ =
     (Data.DataFrame
        [{ Data.name = "y"; col_type = Data.Real };"""


{-| The real output for the invalid program in Examples.md.
-}
realError : String
realError =
    "Parse error: 1:0-1:3syntax error in state 0\nSee parser.messages for context. \nRun menhir --list-errors lib/frontend/parser.mly > lib/frontend/parser.messages to regenerate the messages."


payload : Encode.Value -> Encode.Value -> Encode.Value
payload error code =
    Encode.object [ ( "error", error ), ( "code", code ) ]


decode : Encode.Value -> Result Decode.Error CompileResult
decode =
    Decode.decodeValue Compiler.decoder


suite : Test
suite =
    describe "Compiler.decoder"
        [ test "ok: code without error" <|
            \_ ->
                decode (payload Encode.null (Encode.string realCode))
                    |> Expect.equal (Ok (Compiled { code = realCode, warnings = [] }))
        , test "error: error without code" <|
            \_ ->
                decode (payload (Encode.string realError) Encode.null)
                    |> Expect.equal (Ok (Failed [ realError ]))
        , test "warnings: code and error together keep the code" <|
            \_ ->
                decode (payload (Encode.string "invalid Stan") (Encode.string realCode))
                    |> Expect.equal (Ok (Compiled { code = realCode, warnings = [ "invalid Stan" ] }))
        , describe "malformed payloads"
            [ test "both fields null" <|
                \_ ->
                    decode (payload Encode.null Encode.null)
                        |> Expect.err
            , test "missing field" <|
                \_ ->
                    decode (Encode.object [ ( "code", Encode.string realCode ) ])
                        |> Expect.err
            , test "field of the wrong type" <|
                \_ ->
                    decode (payload Encode.null (Encode.int 1))
                        |> Expect.err
            , test "not an object" <|
                \_ ->
                    decode (Encode.string realCode)
                        |> Expect.err
            ]
        , test "fromValue reports a malformed payload as a failure" <|
            \_ ->
                case Compiler.fromValue (payload Encode.null Encode.null) of
                    Failed [ message ] ->
                        String.contains "Unexpected response" message
                            |> Expect.equal True

                    other ->
                        Expect.fail ("Expected a single failure, got: " ++ Debug.toString other)
        ]
