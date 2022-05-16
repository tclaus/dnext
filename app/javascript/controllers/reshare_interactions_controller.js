import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    initialize() {
        console.debug("Initialized reshare_controller")
    }

    async updateInteractions(event) {
        if (event.detail.fetchResponse.succeeded) {
            event.preventDefault()
            const json = await event.detail.fetchResponse.response.clone().json()
            this.updateElementFooter(json)
        }
    }

    updateElementFooter(json) {
        let post = document.getElementById(json.element_id);
        let post_footer = post.getElementsByClassName("post-interactions");
        post_footer.outerHtml = json.element_footer;
    }
}