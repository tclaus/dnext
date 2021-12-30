module StreamsHelper
  include Pagy::Frontend

  def author_full_name(author)
    "#{author.first_name} #{author.last_name}"
  end
end
