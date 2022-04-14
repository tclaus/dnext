# frozen_string_literal: true

namespace "comments" do
  desc "Extract thread information from comments"
  task migrate_threaded: :environment do
    puts "Extracts threaded information from comments when fetched from a system that supports threaded comments"
    extract_and_migrate
  end

  def extract_and_migrate
    comment_signatures_with_data = CommentSignature
                                   .where.not(additional_data: nil)

    migrate_comments(comment_signatures_with_data)
    puts "Finished"
  end

  def migrate_comments(comment_signatures)
    puts "Found #{comment_signatures.count} comments with data to examine for threaded data"
    migrated_comments = 0
    comment_signatures.find_each do |possible_comment_to_migrate|
      extract_thread_parent_guid(possible_comment_to_migrate)

      migrated_comments += 1
      write_progress(migrated_comments)
    end
  end

  def extract_thread_parent_guid(possible_comment_to_migrate)
    thread_parent_guid = possible_comment_to_migrate.additional_data["thread_parent_guid"]
    if thread_parent_guid.present?
      comment = possible_comment_to_migrate.comment
      comment&.thread_parent_guid = thread_parent_guid
      comment&.save(touch: false)
    end
  end

  def write_progress(migrated_comments)
    puts "Finished #{migrated_comments}" if migrated_comments % 100 == 0
  end
end
