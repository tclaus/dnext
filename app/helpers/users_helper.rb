module UsersHelper
  def owner_image_tag(size = nil)
    person_image_tag(current_user.person, size)
  end
end
