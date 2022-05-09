import {Controller} from "@hotwired/stimulus"
import {queryHelper} from "queryHelper"

export default class extends Controller {
    static targets = ["unlike"]
    controller_path = "/likes";

    connect() {
        queryHelper(this)
    }

    initialized() {
        console.debug("Started single-stream-interactions controller")
    }

    like(event) {
        console.info("Like on post:", this.getPostId())
        event.preventDefault()

        fetch(this.controller_path, {
            signal: this.createAbortController().signal,
            method: 'POST',
            headers: this.defaultHeader(),
            body: JSON.stringify({post_id: this.getPostId()})
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
        console.info("Unlike on single post", this.getPostId())
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
        let actions = this.element.querySelector("#actions")
        actions.outerHTML = data.single_post_actions
    }

    getPostId() {
        return this.element.id.split("_")[1]
    }
}