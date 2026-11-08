module Main exposing (main)

import Browser
import Html exposing (Html, button, div, h2, label, pre, text, textarea)
import Html.Attributes exposing (class, for, id, spellcheck, value)
import Html.Events exposing (onClick, onInput)


main : Program () Model Msg
main =
    Browser.sandbox { init = init, update = update, view = view }


type alias Model =
    { source : String
    , code : String
    , errors : String
    }


init : Model
init =
    { source = ""
    , code = ""
    , errors = ""
    }


type Msg
    = SourceChanged String
    | CompileClicked


update : Msg -> Model -> Model
update msg model =
    case msg of
        SourceChanged source ->
            { model | source = source }

        CompileClicked ->
            case fakeCompile model.source of
                Ok code ->
                    { model | code = code, errors = "" }

                Err error ->
                    { model | code = "", errors = error }


{-| Placeholder until the real compiler is connected.
-}
fakeCompile : String -> Result String String
fakeCompile source =
    if String.isEmpty (String.trim source) then
        Err "Nothing to compile: the input is empty."

    else
        Ok (String.toUpper source)


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
            , pre [ id "code" ] [ text model.code ]
            , h2 [] [ text "Errors" ]
            , pre [ id "errors" ] [ text model.errors ]
            ]
        ]
