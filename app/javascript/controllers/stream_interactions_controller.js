import {Controller} from "@hotwired/stimulus"
import {queryHelper} from "queryHelper"

export default class extends Controller {
    static targets = ["unlike"]
    controller_path = "/likes";

    connect() {
        queryHelper(this)
    }

    initialized() {
        console.debug("Started stream-interactions controller")
    }

    like(event) {
        console.info("Create like on: ", this.getType())
        event.preventDefault()

        fetch(this.controller_path, {
            signal: this.createAbortController().signal,
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

    unlike(event) {
        console.info("Destroy like on: ", this.getType())
        event.preventDefault()

        const own_like_id = this.unlikeTarget.dataset.likeid

        fetch(this.controller_path, {
            signal: this.createAbortController().signal,
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

    replaceInteractionHtml(data) {
        if (this.getType() === "post" || this.getType() === "reshare") {
            let parent = this.element.parentNode
            parent.outerHTML = data.element_footer
        }
        if (this.getType() === "comment") {
            let comment_interactions = this.element.querySelector(".comment-interactions")
            comment_interactions.innerHTML = data.element_footer
        }
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
}