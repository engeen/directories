module Searchable
  extend ActiveSupport::Concern
  included do
    update_index("#{self.name.pluralize.underscore}##{self.name.demodulize.underscore}") { self } if ("#{self.name.pluralize}Index".constantize rescue nil)

    class << self
      def elasticsearch(params={})
        columns = params.delete(:columns)
        columns = columns.map { |k,v| v[:name] } if columns
        options = params.except(*blacklist)

        Searches::DirectorySearch.new(options.merge({fields: search_fields, index: index, columns: columns}))
      end

      protected
      def blacklist
        [:_, :draw, :datatables, :start, :length]
      end

      def index
        index = "#{self.name.pluralize}Index".constantize rescue nil
      end

      def search_fields
        #byebug
        logger.warn("===> search fields for #{self.name}: #{index.types.first rescue "index not found"}")

        type = index.types.first
        begin
          #byebug
          fields = type.mappings_hash[type.type_name.to_sym][:properties].map(&:first)
          logger.warn("===> [#{fields.join(',')}]")
          return fields
        rescue => ex
          logger.error("===> Exception building search fields: #{ex.backgrace}")
          fields = (self.directory_fields + self.edit_directory_fields).reject { |f| f.is_a?(Hash) }.compact.uniq
          logger.warn("===> [#{fields.join(',')}]")
          return fields
        end
      end
    end
  end
end
