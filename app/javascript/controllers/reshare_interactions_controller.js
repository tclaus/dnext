import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    async updateInteractions(event) {
        if (event.detail.fetchResponse.succeeded) {
            event.preventDefault()
            const json = await event.detail.fetchResponse.response.clone().json()
            this.updateStreamElementInteractions(json)
            this.updateSinglePostViewInteractions(json)
        }
    }

    updateStreamElementInteractions(json) {
        let post = document.getElementById(json.element_id)
        let post_footer = post.getElementsByClassName("stream-element-footer")[0]
        if (post_footer !== undefined) {
            post_footer.outerHTML = json.element_footer
        }
    }

    updateSinglePostViewInteractions(json) {
        let post_interactions = document.getElementsByClassName("single-post-interactions")[0]
        if (post_interactions !== undefined) {
            post_interactions.outerHTML = json.single_post_interactions;
        }
    }
}