module Stream
  class Person < Stream::Base
    attr_accessor :person

    def initialize(user, person, _opts={})
      self.person = person
      super(user)
    end

    # @return [ActiveRecord::Association<Post>] AR association of posts
    def posts
      @posts ||= user.present? ? user.posts_from(@person) : @person.posts.where(public: true)
    end
  end
end
