# frozen_string_literal: true

# Thanks for the inspiration of https://joshfrankel.me/blog/a-journey-into-writing-union-queries-with-active-record/
module ActiveRecordUnion
  extend ActiveSupport::Concern

  class_methods do
    def union(*relations)
      raise ArgumentError, "wrong number of arguments (given 0, expected 1+)" if relations.empty?

      valid_relations = relations
                        .select do |relation|
        if table_name != relation.table_name
          raise ArgumentError,
                "type mismatch. Base model table #{table_name} does not match table #{relation.table_name} of " \
                "at least one relation"
        end

        relation.to_sql.present?
      end

      mapped_sql = valid_relations
                   .map(&:to_sql)
                   .join(") UNION (")

      unionized_sql = "((#{mapped_sql})) #{table_name}"

      where(id: from(unionized_sql))
    end
  end
end

ActiveRecord::Base.include ActiveRecordUnion
