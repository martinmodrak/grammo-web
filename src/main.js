// vite-plugin-elm compiles Main.elm and turns it into an ES module exporting Elm.
import { Elm } from "./Main.elm";

Elm.Main.init({ node: document.getElementById("app") });
