class PersonPresenter < BasePresenter
  def relationship
    return false unless current_user

    return :not_sharing unless contact

    %i[mutual sharing receiving].find do |status|
      contact.public_send("#{status}?")
    end || :not_sharing
  end

  def title
    name
  end

  def show_profile_info
    public_details? || own_profile? || person_follows_current_user
  end

  private

  def own_profile?
    current_user.try(:person) == @presentable
  end

  def person_follows_current_user
    return false unless current_user

    contact&.sharing?
  end

  def contact
    @contact ||= (current_user ? current_user.contact_for(@presentable) : Contact.none)
  end
end
