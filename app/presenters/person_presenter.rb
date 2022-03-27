class PersonPresenter < BasePresenter
  def relationship
    return false unless current_user

    return :not_sharing unless contact

    %i[mutual sharing receiving].find do |status|
      contact.public_send("#{status}?")
    end || :not_sharing
  end

  private

  def contact
    @contact ||= (current_user ? current_user.contact_for(@presentable) : Contact.none)
  end
end
