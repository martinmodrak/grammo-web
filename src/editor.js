import { EditorView, basicSetup } from "codemirror";

// <code-editor>: a CodeMirror editor that Elm can use like any other element.
// Elm sets the `value` property to pass text in, and listens for the
// `editor-change` event, whose `detail` is the new text.
class CodeEditor extends HTMLElement {
  #view = null;
  // Holds the text until the editor exists, because Elm sets properties before
  // it adds the element to the page.
  #initialValue = "";

  connectedCallback() {
    if (this.#view) return;
    this.#view = new EditorView({
      doc: this.#initialValue,
      parent: this,
      extensions: [
        basicSetup,
        EditorView.updateListener.of((update) => {
          if (update.docChanged && !this.#applyingValue) {
            this.dispatchEvent(
              new CustomEvent("editor-change", { detail: update.state.doc.toString() }),
            );
          }
        }),
      ],
    });
  }

  // True while a change from Elm is applied, so it isn't reported back to Elm.
  #applyingValue = false;

  get value() {
    return this.#view ? this.#view.state.doc.toString() : this.#initialValue;
  }

  set value(text) {
    if (!this.#view) {
      this.#initialValue = text;
      return;
    }
    // Replacing the document moves the cursor, so only do it for a real change.
    // Elm echoes back what the user typed, and that must be a no-op.
    if (text === this.value) return;
    this.#applyingValue = true;
    this.#view.dispatch({ changes: { from: 0, to: this.#view.state.doc.length, insert: text } });
    this.#applyingValue = false;
  }
}

customElements.define("code-editor", CodeEditor);
