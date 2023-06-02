# frozen_string_literal: true

module UserServices
  class SocialActions
    def initialize(user)
      @user = user
    end

    def comment!(target, text, opts={})
      Comment::Generator.new(user, target, text).create!(opts).tap do
        update_or_create_participation!(target)
      end
    end

    def participate!(target, opts={})
      Participation::Generator.new(user, target).create!(opts)
    end

    def participate_in_poll!(target, answer, opts={})
      PollParticipation::Generator.new(user, target, answer).create!(opts).tap do
        update_or_create_participation!(target)
      end
    end

    def like!(target, opts={})
      Like::Generator.new(user, target).create!(opts).tap do
        update_or_create_participation!(target)
      end
    end

    def like_comment!(target, opts={})
      Like::Generator.new(user, target).create!(opts)
    end

    def reshare!(target, opts={})
      raise I18n.t("reshares.create.error") if target.author.guid == user.guid

      build_post(:reshare, root_guid: target.guid).tap do |reshare|
        reshare.text = opts[:text]
        reshare.save!
        update_or_create_participation!(target)
        Diaspora::Federation::Dispatcher.defer_dispatch(user, reshare)
      end
    end

    def build_conversation(opts={})
      Conversation.new do |c|
        c.author = user.person
        c.subject = opts[:subject]
        c.participant_ids = [*opts[:participant_ids]] | [person_id]
        c.messages_attributes = [
          {author: user.person, text: opts[:message][:text]}
        ]
      end
    end

    def build_message(conversation, opts={})
      conversation.messages.build(
        text:   opts[:text],
        author: user.person
      )
    end

    def update_or_create_participation!(target)
      return if target.author == user.person

      participation = user.participations.find_by(target_id: target)
      if participation.present?
        participation.update!(count: participation.count.next)
      else
        participate!(target)
      end
    end

    private

    attr_reader :user
  end
end
