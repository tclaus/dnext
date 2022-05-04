import {Controller} from "@hotwired/stimulus"
const timeoutMs = 30_000;

export default class Base extends Controller {

    createAbortController() {
        const abort_controller = new AbortController();
        setTimeout(() => abort_controller.abort(), timeoutMs);
        return abort_controller
    }

    defaultHeader() {
        return  {
            'Content-Type': 'application/json',
            Accept: "application/json",
            'X-CSRF-Token': this.getCSRFToken(),
        }
    }

    getCSRFToken() {
        return document.getElementsByName(
            "csrf-token"
        )[0].content;
    }
}