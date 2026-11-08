module Main exposing (main)

import Browser
import Compiler exposing (CompileResult(..))
import Html exposing (Html, button, div, h2, label, pre, text, textarea)
import Html.Attributes exposing (class, for, id, spellcheck, value)
import Html.Events exposing (onClick, onInput)
import Json.Encode as Encode


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
            ( model, Compiler.compile model.source )

        GotResult value ->
            ( { model | result = Just (Compiler.fromValue value) }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Compiler.compiled GotResult


view : Model -> Html Msg
view model =
    let
        ( code, diagnostics ) =
            case model.result of
                Nothing ->
                    ( "", [] )

                Just (Compiled compiled) ->
                    ( compiled.code, compiled.warnings )

                Just (Failed errors) ->
                    ( "", errors )
    in
    div [ class "layout" ]
        [ div [ class "pane" ]
            [ label [ for "source" ] [ text "Grammo" ]
            , textarea
                [ id "source"
                , value model.source
                , onInput SourceChanged
                , spellcheck False
                ]
                []
            , button [ onClick CompileClicked ] [ text "Compile" ]
            ]
        , div [ class "pane" ]
            [ h2 [] [ text "Stan code" ]
            , pre [ id "code" ] [ text code ]
            , h2 [] [ text "Errors" ]
            , pre [ id "errors" ] [ text (String.join "\n\n" diagnostics) ]
            ]
        ]
