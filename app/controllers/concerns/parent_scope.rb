module ParentScope
  extend ActiveSupport::Concern

  SCOPE_ID = '_id'
  SCOPE_REGEXP = Regexp.new(SCOPE_ID)

  def parent_scope
    @parent_resource ||= find_scope
  end

  def find_scope
    @parent_scopes = []
    @where_clauses = []
    nested_objects.each do |obj|
      @parent_scopes.push find_object(obj)
    end
    @parent_resource = @parent_scopes.last
  end

  def find_object(obj)
    key = obj.keys.first
    value = obj[key]
    klass = obj.keys.first.remove(SCOPE_ID)
    begin
      "#{self.class.parent.to_s}::#{klass.classify}".constantize.find(value)
    rescue
      begin
        klass.camelize.constantize.find value
      rescue
        @where_clauses.push(obj)
        nil
      end
    end
  end

  def nested_objects
    nested = params.find_all { |route| route.first.match(SCOPE_REGEXP) }
    nested.map { |route| { route.first => route.last } }
  end

  def current_subject
		if @parent_scope
      @parent_scope.to_sym
		else
      parent_scope.class.name.underscore.pluralize.to_sym if parent_scope
		end
	end

  def where_clauses
    if @where_clauses.present?
      clauses = @where_clauses
      begin
        klass = self.class.name.gsub('sController', '').constantize
      rescue
      end
      if defined?(klass) && klass.present?
        clauses = clauses.select{ |h| h if klass.new.respond_to?(h.keys.first) }
      end
      clauses.reduce {|a,b| a.merge(b) if b.present? }
    end
  end

  protected
  def resource_collection
    collection = if parent_scope
      # add_breadcrumb(I18n.t("breadcrumbs.#{@parent_resource.class.name.underscore}", name: @parent_resource.to_s), url_for(@parent_resource))
      @parent_resource.send(controller_name)
    else
      if defined? load_type
        load_type.all
      else
        begin
          self.class.name.singularize.constantize.all
        rescue
        end
      end
    end
    where_clauses.present? ? collection.where(where_clauses) : collection
  end
end
