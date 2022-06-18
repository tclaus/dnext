# DNEXT

A proof-of-concept to rebuild DIASPORA* without legacy templates for views. 
This is also build on Ruby 3 and Rails 7 with its new Turbo and Stimulus helpers.

## Why

Diaspora is a long running project with a long history. Dnext will test if it is possible to rebuild 
it with modern ruby code, modern rails code and get rid of the old templating system. 

All together this should make it easier for new developers to join in.

## How to use it
It currently relies on an existing Diaspora installation and can work side-by-side for developing and testing.
However to get it running you must: 
* Setup the diaspora.config and database.yml files
  * Use a subdomain like dnext.societas.online in configuration
* Start a migration
* Its planned to use puma (and not unicorn) start locally with $: Rails s command  (Contributions here are welcome)
* Then you should use the same credentials to log in as with the main installation

See it running under https://dnext.societas.online 

## What is in it? 
* Most features from societas pod
* Stream (public and Users stream)
* Like, Reshare
* Reshare with Text
* Users Stream (with Photos)
* Single Post view


## What is missing?

Features and function are adapted one-after-another.
Currently only Public and Stream is implemented

* Writing Posts and Comments
* A dialog to report, hide and block users on posts
* Notifications
* User Settings
* Admin and Moderator views
* Trending (or most used) tags like in societas

## How can you help?

Grab any issue from the issues list and make a pull request. For major changes, please open an issue first to discuss 
what you would like to change.

Please make sure to update tests as appropriate

