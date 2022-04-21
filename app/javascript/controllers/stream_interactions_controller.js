import {Controller} from "@hotwired/stimulus"

const timeout = 30_000;

export default class extends Controller {
    static targets = ["unlike"]
    controller_path = "/likes";

    initialized() {
        console.log("Started stimulus container")
    }

    destroyLike(event) {
        console.info("Destroy like on: ", this.getType())
        event.stopPropagation()

        const own_like_id = this.unlikeTarget.dataset.likeid

        const abort_controller = new AbortController();
        const timeoutId = setTimeout(() => abort_controller.abort(), timeout);

        fetch(this.controller_path, {
            signal: abort_controller.signal,
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': this.getCSRFToken(),
            },
            body: JSON.stringify({id: own_like_id})
        })
            .then(response => {
                if (!response.ok) {
                    console.error("Could not remove like: " + response.statusText)
                } else {
                    console.info("Remove like received")
                }
            })
    }

    createLike(event) {
        console.info("Create like on: ", this.getType())
        event.stopPropagation()

        const abort_controller = new AbortController();
        const timeoutId = setTimeout(() => abort_controller.abort(), timeout);

        fetch(this.controller_path, {
            signal: abort_controller.signal,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': this.getCSRFToken(),
            },
            body: JSON.stringify(this.createLikeParams())
        })
            .then(response => {
                if (!response.ok) {
                    console.error("Could not create like: " + response.statusText)
                } else {
                    console.info("Create like received")
                }
            })
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