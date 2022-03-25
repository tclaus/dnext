# frozen_string_literal: true

class PhotosController < ApplicationController
  before_action :authenticate_user!, except: %i[show index]
  respond_to :html, :json

  def show
    @photo = if user_signed_in?
               current_user.photos_from(Person.find_by(guid: params[:person_id])).where(id: params[:id]).first
             else
               Photo.where(id: params[:id], public: true).first
             end

    raise ActiveRecord::RecordNotFound unless @photo
  end

  def index
    @post_type = :photos
    @person = Person.find_by(guid: params[:person_id])
    authenticate_user! if @person.try(:remote?) && !user_signed_in?
    @presenter = PersonPresenter.new(@person, current_user)

    if @person
      @contact = current_user.contact_for(@person) if user_signed_in?
      @posts = Photo.visible(current_user, @person, :all, max_time)
      respond_to do |format|
        format.all do
          render "people/show", layout: "with_header"
        end
        format.json { render_for_api :backbone, json: @posts, root: :photos }
      end
    else
      flash[:error] = I18n.t "people.show.does_not_exist"
      redirect_to people_path
    end
  end
end
