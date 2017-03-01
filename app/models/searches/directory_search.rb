module Searches
  class DirectorySearch
    attr_accessor :params

    def initialize(_params)
      @params = OpenStruct.new(_params)
      if @params.fields
        @params.fields.each do |field|
          Rails.logger.warn("===> DS processing field #{field}")

          self.define_singleton_method("#{field}_filter") do
            if _params[field].is_a?(Array)
              index.filter(terms: {"#{field}" => _params[field]}) if _params[field].present?
            else
              index.filter(term: {"#{field}" => _params[field]}) if _params[field].present?
            end
          end
        end
      end
    end

    def result
      #byebug
      # We can merge multiple scopes

      [all, query_string, sort, *fields.map{|f| send("#{f}_filter")}].compact.reduce(:merge)
    end

    protected
    def fields
      params.fields ||= []
    end

    def index
      params.index
    end

    def all
      if self.respond_to?(:deleted_filter)
        index.filter{ deleted == false }
      else
        index.filter { match_all }
      end
    end

    def query
      params.query || params.search[:value]
    end

    # Using query_string advanced query for the main query input
    def query_string
      _f = @params.fields.include?(:full_text) ? [:full_text] : fields
      # byebug
      a = query.gsub('/', '').scan( /"[^"]+"|[^ ]+/ ).map do |word|
        if word[0] === '"'
          m = word.match( /^"(.*)"$/ );
          word = m ? m[1] : word;
        end
        Unicode.downcase(word.gsub('"', ''))
      end
      _q = '(' + a.join('* AND ') + '*)'
      # _q = '/(?=.*?'+a.join( ')(?=.*?' )+').*/';
      #byebug
      index.filter{ ~q(query_string: {fields: _f, query: "#{_q}", default_operator: 'or'}) } if _q.present? && _f.present?

      #index.query(multi_match: {query: "#{_q}*", fields: _f}) if _q.present? && _f.present
    end

    def sort_column
      if @params.order && @params.columns
        begin
          column = @params.columns[@params.order["0"]["column"].to_i]
          order  = @params.order["0"]["dir"]
          { column => order }
        rescue => e
          Rails.logger.error(e)
        end
      end
    end

    def sort
      sort = sort_column.present? ? sort_column : {id: :asc}
      index.order(sort)
    end

  end
end
