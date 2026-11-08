port module Main exposing (main)

import Browser
import Compiler exposing (CompileResult(..))
import Html exposing (Html, button, div, h2, pre, text)
import Html.Attributes exposing (class, id, property)
import Html.Events exposing (on, onClick)
import Json.Decode as Decode
import Json.Encode as Encode


port compile : String -> Cmd msg


port compiled : (Encode.Value -> msg) -> Sub msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { source : String
    , result : Maybe CompileResult
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { source = "", result = Nothing }, Cmd.none )


type Msg
    = SourceChanged String
    | CompileClicked
    | GotResult Encode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SourceChanged source ->
            ( { model | source = source }, Cmd.none )

        CompileClicked ->
            ( model, compile model.source )

        GotResult value ->
            ( { model | result = Just (Compiler.fromValue value) }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    compiled GotResult


view : Model -> Html Msg
view model =
    let
        ( code, diagnostics ) =
            case model.result of
                Nothing ->
                    ( "", [] )

                Just (Compiled success) ->
                    ( success.code, success.warnings )

                Just (Failed errors) ->
                    ( "", errors )
    in
    div [ class "layout" ]
        [ div [ class "pane" ]
            [ h2 [] [ text "Grammo" ]
            , codeEditor model.source
            , button [ onClick CompileClicked ] [ text "Compile" ]
            ]
        , div [ class "pane" ]
            [ h2 [] [ text "Stan code" ]
            , pre [ id "code" ] [ text code ]
            , h2 [] [ text "Errors" ]
            , pre [ id "errors" ] [ text (String.join "\n\n" diagnostics) ]
            ]
        ]


codeEditor : String -> Html Msg
codeEditor source =
    Html.node "code-editor"
        [ property "value" (Encode.string source)
        , on "editor-change" (Decode.map SourceChanged (Decode.field "detail" Decode.string))
        ]
        []
