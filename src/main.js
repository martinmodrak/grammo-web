// Importing a CSS file is a Vite feature: it adds the styles to the page in dev
// and bundles them into a .css file in the production build.
import "./style.css";
// Registers <code-editor>. This has to happen before Elm first renders it.
import "./editor.js";
// vite-plugin-elm compiles Main.elm and turns it into an ES module exporting Elm.
import { Elm } from "./Main.elm";

const app = Elm.Main.init({ node: document.getElementById("app") });

// Elm -> JS: `subscribe` runs this callback for each `compile` command.
// JS -> Elm: `send` delivers the object to the `compiled` subscription.
// `grammoc` is a global created by the grammo.js script tag in index.html.
app.ports.compile.subscribe((source) => {
  app.ports.compiled.send(grammoc.compile(source));
});
