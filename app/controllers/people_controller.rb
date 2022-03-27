# frozen_string_literal: true

class PeopleController < ApplicationController
  before_action :authenticate_user!, except: %i[show hovercard]
  before_action :find_person, only: %i[show hovercard]
  before_action :authenticate_if_remote_profile!, only: %i[show]
  include Pagy::Backend

  rescue_from ActiveRecord::RecordNotFound do
    render file: Rails.root.join("public/404").to_s,
           format: :html, layout: false, status: :not_found
  end

  rescue_from Diaspora::AccountClosed do
    respond_to do |format|
      format.any { redirect_back fallback_location: root_path, notice: t("people.show.closed_account") }
      format.json { head :gone }
    end
  end

  helper_method :search_query

  def index
    # person?q=...
    @aspect = :search
    limit = params[:limit] ? params[:limit].to_i : 15

    @people = Person.search(search_query, current_user)

    respond_to do |format|
      format.json do
        @people = @people.limit(limit)
        render json: @people
      end

      format.any(:html, :mobile) do
        # only do it if it is a diaspora*-ID
        if diaspora_id?(search_query)
          @people = Person.left_outer_joins(:pod)
                          .where(diaspora_handle: search_query.downcase, closed_account: false)
          # TODO: Dont make a background fetch, if search_query references a pod which is blocked
          background_search(search_query) if @people.empty?
        end
        @people = @people.where("(pods.blocked = FALSE or pods.blocked is NULL)")
        @people = @people.paginate(page: params[:page], per_page: 15)
        @hashes = hashes_for_people(@people, @aspects)
      end
    end
  end

  def refresh_search
    @aspect = :search
    @people = Person.where(diaspora_handle: search_query.downcase, closed_account: false)
    @answer_html = ""
    unless @people.empty?
      @hashes = hashes_for_people(@people, @aspects)

      self.formats = formats + [:html]
      @answer_html = render_to_string partial: "people/person", locals: @hashes.first
    end
    render json: {search_html: @answer_html, contacts: gon.preloads[:contacts]}.to_json
  end

  # renders the persons user profile page
  def show
    mark_corresponding_notifications_read if user_signed_in?
    @presenter = PersonPresenter.new(@person, current_user)
    @contact = current_user.contact_for(@person) if user_signed_in?

    stream_responder
  end

  def stream_responder
    @stream_builder_object = person_stream
    @title = @person.diaspora_handle
    @pagy, @stream = pagy(person_stream.stream_posts)
    @photos_count =  Photo.visible(current_user, @person).count(:all)

    respond_to do |format|
      format.html { render "people/show", layout: "with_header" } # Person Profile
      format.json do
        render json: {
          entries:    render_to_string(partial: "stream_elements",
                                       formats: [:html]),
          pagination: view_context.pagy_nav(@pagy)
        }
      end
    end
  end

  # hovercards fetch some the persons public profile data via json and display
  # it next to the avatar image in a nice box
  def hovercard
    respond_to do |format|
      format.all do
        redirect_to action: "show", id: params[:person_id]
      end

      format.json do
        render json: PersonPresenter.new(@person, current_user).hovercard
      end
    end
  end

  private

  def find_person
    username = params[:username]
    @person = Person.find_from_guid_or_username(
      id:       params[:id] || params[:person_id],
      username: username
    )

    raise ActiveRecord::RecordNotFound if @person.nil?
    raise Diaspora::AccountClosed if @person.closed_account?
  end

  def background_search(search_query)
    Workers::FetchWebfinger.perform_async(search_query)
    @background_query = search_query.downcase
  end

  def hashes_for_people(people, aspects)
    people.map {|person|
      {
        person:  person,
        contact: current_user.contact_for(person) || Contact.new(person: person),
        aspects: aspects
      }.tap {|hash|
        gon_load_contact(hash[:contact])
      }
    }
  end

  def search_query
    @search_query ||= params[:q] || params[:term] || ""
  end

  def diaspora_id?(query)
    !(query.nil? || query.lstrip.empty?) && Validation::Rule::DiasporaId.new.valid_value?(query.downcase).present?
  end

  # view this profile on the home pod, if you don't want to sign in...
  def authenticate_if_remote_profile!
    authenticate_user! if @person.try(:remote?)
  end

  def mark_corresponding_notifications_read
    Notification.where(recipient_id: current_user.id, target_type: "Person", target_id: @person.id,
                       unread: true).each do |n|
      n.set_read_state(true)
    end
  end

  def person_stream
    @person_stream ||= Stream::Person.new(current_user, @person)
  end
end
