port module Main exposing (main)

import Browser
import Html exposing (Html, button, div, h2, label, pre, text, textarea)
import Html.Attributes exposing (class, for, id, spellcheck, value)
import Html.Events exposing (onClick, onInput)
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
    , rawResult : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { source = "", rawResult = "" }, Cmd.none )


type Msg
    = SourceChanged String
    | CompileClicked
    | Compiled Encode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SourceChanged source ->
            ( { model | source = source }, Cmd.none )

        CompileClicked ->
            ( model, compile model.source )

        Compiled result ->
            ( { model | rawResult = Encode.encode 2 result }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    compiled Compiled


view : Model -> Html Msg
view model =
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
            , pre [ id "code" ] [ text model.rawResult ]
            , h2 [] [ text "Errors" ]
            , pre [ id "errors" ] []
            ]
        ]
