import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ['card', 'content']
    static values = {
        url: String
    }

    connect() {
        this.abortController = new AbortController()
        this.signal = this.abortController.signal
    }

    async show(event) {
        let content = null

        if (this.hasContentTarget) {
            content = this.contentTarget.innerHTML
        } else {
            if (this.signal.aborted) {
                this.abortController = new AbortController();
                this.signal = this.abortController.signal;
            }
            content = await this.fetch()
        }

        if (!content) return

        const fragment = document.createRange().createContextualFragment(content)
        event.target.appendChild(fragment)
    }

    hide() {
        if (!this.signal.aborted) {
            this.abortController.abort()
        }

        if (this.hasCardTarget) {
            this.cardTarget.remove()
        }
    }

    async fetch() {
        if (!this.remoteContent) {
            if (!this.hasUrlValue) {
                console.error('[stimulus-popover] You need to pass an url to fetch the popover content.')
                return
            }

            const response = await fetch(this.urlValue, {signal: this.signal})
                .catch(function (err) {
                    if (err.name === 'AbortError') {
                        // handle abort()  We need to catch the error thrown by the abort.
                        // In our case, we don't want to do anything if we abort.
                    } else {
                        throw err;
                    }
                })
            this.remoteContent = await response.text()
        }

        return this.remoteContent
    }
}