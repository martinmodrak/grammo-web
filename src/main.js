// Importing a CSS file is a Vite feature: it adds the styles to the page in dev
// and bundles them into a .css file in the production build.
import "./style.css";
// vite-plugin-elm compiles Main.elm and turns it into an ES module exporting Elm.
import { Elm } from "./Main.elm";

// Placeholder with the same result shape as the real compiler.
function stubCompile(source) {
  return { error: null, code: `// Stub received ${source.length} characters` };
}

const app = Elm.Main.init({ node: document.getElementById("app") });

// Elm -> JS: `subscribe` runs this callback for each `compile` command.
// JS -> Elm: `send` delivers the object to the `compiled` subscription.
app.ports.compile.subscribe((source) => {
  app.ports.compiled.send(stubCompile(source));
});
