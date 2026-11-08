// Importing a CSS file is a Vite feature: it adds the styles to the page in dev
// and bundles them into a .css file in the production build.
import "./style.css";
// vite-plugin-elm compiles Main.elm and turns it into an ES module exporting Elm.
import { Elm } from "./Main.elm";

Elm.Main.init({ node: document.getElementById("app") });
