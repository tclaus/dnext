# frozen_string_literal: true

class PeopleController < ApplicationController
  before_action :authenticate_user!, except: %i[show stream hovercard]
end
