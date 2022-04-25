import {Controller} from "@hotwired/stimulus"

const timeoutMs = 30_000;

export default class extends Controller {
    static targets = ["unlike"]
    controller_path = "/likes";

    initialized() {
        console.debug("Started stimulus container")
    }

    destroyLike(event) {
        console.info("Destroy like on: ", this.getType())
        event.preventDefault()

        const own_like_id = this.unlikeTarget.dataset.likeid

        const abort_controller = new AbortController();
        const timeoutId = setTimeout(() => abort_controller.abort(), timeoutMs);

        fetch(this.controller_path, {
            signal: abort_controller.signal,
            method: 'DELETE',
            headers: this.defaultHeader(),
            body: JSON.stringify({id: own_like_id})
        })
            .then(response => response.json())
            .then(data => {
                console.info("Remove like received")
                this.replaceInteractionHtml(data)
            })
            .catch((error) => {
                console.error("Error in removing a like: ", error)
            })
    }

    createLike(event) {
        console.info("Create like on: ", this.getType())
        event.preventDefault()

        const abort_controller = new AbortController();
        const timeoutId = setTimeout(() => abort_controller.abort(), timeoutMs);

        fetch(this.controller_path, {
            signal: abort_controller.signal,
            method: 'POST',
            headers: this.defaultHeader(),
            body: JSON.stringify(this.createLikeParams())
        })
            .then(response => response.json())
            .then(data => {
                console.info("Create like received")
                this.replaceInteractionHtml(data)
            })
            .catch((error) => {
                console.error("Error in creating a new like: ", error)
            })
    }

    defaultHeader() {
        return  {
            'Content-Type': 'application/json',
            Accept: "application/json",
            'X-CSRF-Token': this.getCSRFToken(),
        }
    }

    replaceInteractionHtml(data) {
        let parent = this.element.parentNode
        parent.outerHTML = data.element_footer
    }

    createLikeParams() {
        if (this.getType() === "post" || this.getType() === "reshare") {
            return {post_id: this.getId()}
        }

        if (this.getType() === "comment") {
            return {comment_id: this.getId()}
        }
    }

    // returns post or comment as a type
    getType() {
        return this.element.id.split("_")[0]
    }

    getId() {
        return this.element.id.split("_")[1]
    }

    getCSRFToken() {
        return document.getElementsByName(
            "csrf-token"
        )[0].content;
    }
}