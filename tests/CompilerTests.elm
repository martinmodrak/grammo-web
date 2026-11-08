module CompilerTests exposing (suite)

import Compiler exposing (CompileResult(..))
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


sampleCode : String
sampleCode =
    "sample code"


sampleError : String
sampleError =
    "sample error"


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
                decode (payload Encode.null (Encode.string sampleCode))
                    |> Expect.equal (Ok (Compiled { code = sampleCode, warnings = [] }))
        , test "error: error without code" <|
            \_ ->
                decode (payload (Encode.string sampleError) Encode.null)
                    |> Expect.equal (Ok (Failed [ sampleError ]))
        , test "warnings: code and error together keep the code" <|
            \_ ->
                decode (payload (Encode.string sampleError) (Encode.string sampleCode))
                    |> Expect.equal (Ok (Compiled { code = sampleCode, warnings = [ sampleError ] }))
        , describe "malformed payloads"
            [ test "both fields null" <|
                \_ ->
                    decode (payload Encode.null Encode.null)
                        |> Expect.err
            , test "missing field" <|
                \_ ->
                    decode (Encode.object [ ( "code", Encode.string sampleCode ) ])
                        |> Expect.err
            , test "field of the wrong type" <|
                \_ ->
                    decode (payload Encode.null (Encode.int 1))
                        |> Expect.err
            , test "not an object" <|
                \_ ->
                    decode (Encode.string sampleCode)
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
