// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

import "popper"
import "bootstrap"

import "controllers"
import {queryHelper} from "./controllers/mixins/queryHelper";

import "custom/tooltips"

import LocalTime from "local-time"
LocalTime.start()
