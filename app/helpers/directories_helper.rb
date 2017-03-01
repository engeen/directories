module DirectoriesHelper
  def flash_messages(_opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type.to_sym)} fade in") do
               concat content_tag(:button, 'x', class: 'close', data: { dismiss: 'alert' })
               concat raw(message)
             end)
    end
    nil
  end

  def bootstrap_class_for(flash_type)
    { success: 'alert-success', error: 'alert-danger', alert: 'alert-warning', notice: 'alert-info' }[flash_type] || flash_type.to_s
  end

  def sanitized_object_name(f)
     f.object_name.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")
  end

  def field_id_for(f,method, form_id = false)
    str = "#{sanitized_object_name(f)}_#{method.to_s.sub(/\?$/,"")}"
    if form_id && f.options[:html].present?
      f_id = f.options[:html][:id]
      "#{str}_#{f_id}"
    else
      str
    end
  end

  def edit_directory_fields_for(resource)
    #byebug
    if resource.persisted?
      controller.edit_overrides_for(resource.class) || resource.class.edit_directory_fields
    else
      controller.create_overrides_for(resource.class) || resource.class.create_directory_fields
    end
  end

  def directory_columns_for(resource_class, fields=nil, no_templates = false)
    columns = []
    _fields = fields || (controller.display_overrides_for(resource_class) || resource_class.directory_fields)
    #byebug
    _fields.each do |field|
      if no_templates
        columns << field
        next
      end

      if field.is_a?(Hash)
        field[field.keys.first].each do |subfield|
          if fields.nil? && lookup_context.exists?("item_#{field.keys.first}_#{subfield}", controller.controller_path , true)
            columns << {field: "#{field.keys.first}.#{subfield}", template: "#{controller.controller_path}/item_#{field.keys.first}_#{subfield}" }
          elsif lookup_context.exists?("item_#{field.keys.first}_#{subfield}", resource_class.name.tableize , true)
            columns << {field: "#{field.keys.first}.#{subfield}", template: "#{resource_class.name.tableize}/item_#{field.keys.first}_#{subfield}" }
          else
            columns <<  "#{field.keys.first}.#{subfield}"
          end

        end
      else
        if fields.nil? && lookup_context.exists?("item_#{field}", controller.controller_path, true)
          columns << {field: field, template: "#{controller.controller_path}/item_#{field}" }
        elsif lookup_context.exists?("item_#{field}", resource_class.name.tableize , true)
          columns << {field: field, template: "#{resource_class.name.tableize}/item_#{field}" }
        else
          columns << field
        end
      end
    end
    #byebug
    columns
  end

  def directory_tab_builder(tabs = [], &block)
    tabs = [tabs] unless tabs.is_a?(Array)
    tabs.map do |tab_id|
      if tab_id.is_a?(Hash)
        {
         tab_id: tab_id[:id],
         tab_data: {partial: "directories/tab_link", tab_id:  tab_id[:id], title: I18n.t(:"directory.tabs.#{tab_id[:id]}"), active:  tab_id[:active] },
         tab_content: block_given? ? capture(tab_id[:id], true, &block) : ""
        }
      else
        {
         tab_id: tab_id,
         tab_data: {partial: "directories/tab_link", tab_id: tab_id, title:  I18n.t(:"directory.tabs.#{tab_id}")  },
         tab_content: block_given? ? capture(tab_id, &block) : ""
        }
      end
    end
  end

  def find_render_template(name, options= {})
    formats = options.select {|k,v| k == :formats}
    formats = { formats: [:html] } unless options.present?

    if lookup_context.exists?("#{name}_item", controller.controller_path , true, [], formats)
      "#{controller.controller_path}/#{name}_item"
    elsif lookup_context.exists?("#{name}_item", @resource_class.name.tableize , true, [], formats)
      "#{@resource_class.name.tableize}/#{name}_item"
    elsif lookup_context.exists?("#{name}_item", 'directories' , true, [], formats)
      "directories/#{name}_item"
    else
      nil
    end
  end

  def directory_render(name, options = {})
    # partial = find_render_template(name, options)
    # byebug
    # @_partial = {} unless @_partial
    # unless @_partial[name]
    #   if lookup_context.exists?(name, controller.controller_path , true, [], formats)
    #     @_partial[name]  =  "#{controller.controller_path}/#{name}"
    #   elsif lookup_context.exists?(name, @resource_class.name.tableize , true, [], formats)
    #     @_partial[name] =   "#{@resource_class.name.tableize}/#{name}"
    #   else
    #     @_partial[name] =  "directories/#{name}"
    #   end
    # end
    # formats = options.select {|k,v| k== :formats}
    # formats = { formats: [:html] } unless options.present?
    if name.is_a?(Hash)
      options = name
      name = options[:partial].present? ? options[:partial] : options[:template]
    end

    partial = options[:template].nil?
    formats = options.select {|k,v| k== :formats}
    formats = { formats: [:html] } unless options.present?

    directory_template_exist?(name, partial, options)
    if @_partial[name]
      hash = partial ? { :partial =>  @_partial[name] } : { :template =>  @_partial[name] }
      render(hash.reverse_merge(options).merge(formats))
    end
  end


  def directory_template_exist?(name, partial, options = {})
    # byebug
    formats = options.select {|k,v| k== :formats}
    formats = { formats: [:html] } unless options.present?

    #byebug if name == "s_item_sessid"
    @_partial = {} unless @_partial
    unless @_partial.has_key?(name)
      if lookup_context.exists?(name, controller.controller_path , partial, [], formats)
        @_partial[name]  =  "#{controller.controller_path}/#{name}"
        return true
      elsif lookup_context.exists?(name, @resource_class.name.tableize , partial, [], formats)
        @_partial[name] =   "#{@resource_class.name.tableize}/#{name}"
        return true
      elsif lookup_context.exists?(name, "directories", partial, [], formats)
        @_partial[name] =  "directories/#{name}"
        return true
      else
        @_partial[name] = nil
        return false
      end
    else
      return !@_partial[name].nil?
    end

  end


  def content_header(options = {title: "", subtitle: "", icon: ""}, &block)

    options.merge!(:body => capture(&block)) if block_given?
    render(partial: "common/content_header", locals: options)
  end

  def datatable_widget(id,
    options = {
      icon: "",
      title: "",
      source_url: "",
      columns: [],
      order_by: [],
      buttons: [] }, &block)

    options.merge!(id: id, :body => "")
    options.merge!(:body => capture(&block)) if block_given?
    #byebug
    render(partial: "common/datatable_widget", locals: options)
  end

  def freight_pill(caption, value, options = {})
    %(
     	<h4 class="freight-pill">
        <span class="label label-sm label-success #{begin
                                         options[:class]
                                       rescue
                                         ''
                                       end}">
          <span>#{caption} #{value} </span>
        </span>
      </h4>
     ).html_safe
  end

  def scope_t(resource, field)
    scoped = @parent_scope || @parent_resource
    if scoped.present? && !scoped.is_a?(String)
      scoped = scoped.class.name.underscore
    end
    t("directory.#{scoped ? scoped.singularize + '.' : ''}#{resource.class.name.underscore}.fields.#{field}")
  end

  def can_render?(control_hash)
    control_hash[:render].nil? || control_hash[:render]
  end

  def nested_fields_for(resource_class, &block)
    #byebug
    index = 0
    resource_class.directory_nested.each do |nested|
      if nested.is_a?(Hash)
        scope = nested[:scope]
        unless scope.is_a?(Array)
          scope = [scope]
        end
        if (scope.compact.empty? || @parent_scope.nil? || scope.map(&:to_s).include?(@parent_scope))
          yield nested, index if block_given?
          index += 1
        end
      else
        yield nested, index if block_given?
        index += 1
      end
    end
  end

  def select_options(f, field, control_hash)
    # byebug
    if f.object.send(field).present?
      {}
    else
      control_hash[:selected] ? { selected: (control_hash[:selected].is_a?(Symbol) ? send(control_hash[:selected]) : control_hash[:selected]) } : {}
    end
  end
end
