class Participation < ApplicationRecord
  include Diaspora::Federated::Base
  include Diaspora::Fields::Guid
  include Diaspora::Fields::Author
  include Diaspora::Fields::Target

  class Generator < Diaspora::Federated::Generator
    def self.federated_class
      Participation
    end

    def relayable_options
      {target: @target}
    end
  end

  def unparticipate!
    if count == 1
      destroy
    else
      update!(count: count.pred)
    end
  end

  # @return [Array<Person>]
  def subscribers
    [target.author]
  end
end
