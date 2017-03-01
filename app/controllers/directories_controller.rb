# Обеспечивает базовые механизмы CRUD-операций с моделями Directory (концерн)
# Представления контроллера включают в себя функции интеграции Datatables
class DirectoriesController < ApplicationController
  before_action :authenticate_user!
  include DirectoryOverrides

  before_action :validate_user

  @@_directory_controls = {}
  @@_directory_buttons = {}

  helper_method :_directory_attrs
  helper_method :control_for


  helper_method :get_directory_buttons

  before_filter :init_directory
  before_filter :load_type
  before_filter :load_resource, only: [:show, :edit, :update, :destroy]
  before_filter :on_single_resource, only:[:show, :update]

  before_action :set_title

  def index
    per = (params[:length] || 20).to_i
    page = params[:start].to_i / per + 1 if params[:start].present?

    @resources = begin
        @resource_class.elasticsearch(params).result.per(per).page(page).only(:id).load(@resource_class.name.underscore => { scope: -> { @resource_class } } )
    rescue Exception => e
      # byebug
      Rails.logger.debug("="*80)
      Rails.logger.debug(e)
      Rails.logger.debug("="*80)
      resource_collection
    end

    #byebug
    #sleep(0)
    respond_to do |format|
      format.js {}
      format.html { @resources = resource_collection}
      format.json do
        unless params.has_key?(:datatables)
          render "index_for_selectivity"
        end

      end
    end
  end

  def new
    @resource = resource_collection.new
    respond_to do |format|
      format.js {}
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @resource }
      format.js {}
      format.html {}
      format.pdf do
        render pdf: @resource.class.name.underscore, layout: "pdf"   # Excluding ".pdf" extension.
      end

    end
  end

  def edit
    respond_to do |format|
      format.js {}
    end
  end

  def create
    #byebug


    @resource =  resource_collection.build(resource_params)
    if params.has_key?(:just_validate)
      @resource.valid?
    else
      # byebug
      @resource.save
      begin
        unless @resource.errors.any?
          flash.now[:success] = t "common.messages.#{@resource.class.name.underscore}.create.success",
            resource: (url_for([@parent_scope, @parent_resource, @resource]) rescue url_for([@parent_scope, @resource])), default: "Ресурс успешно создан"
        end
      rescue
      end
    end

    respond_to do |format|
      format.js {}
      format.json { render json: @resource }
    end
  end


  def update
      if params[:restore]
        @resource.restore
        @resource.save!
      else
        @resource.update_attributes(resource_params)
      end
      #byebug
      begin
        unless @resource.errors.any?
          flash.now[:success] = t "common.messages.#{@resource.class.name.underscore}.update.success",
            resource: (url_for([@parent_scope, @parent_resource, @resource]) rescue url_for([@parent_scope, @resource])), default: "Ресурс успешно обновлен"
        end
      rescue
      end

    respond_to do |format|
      format.js {}
    end
  end

  def inplace_popup
  end

  def destroy
    @resource.destroy
    begin
      unless @resource.errors.any?
        flash.now[:success] = t "common.messages.#{@resource.class.name.underscore}.destroy.success",
          resource: (url_for([@parent_scope, @parent_resource, @resource]) rescue url_for([@parent_scope, @resource])), default: "Ресурс успешно удален"
      end
    rescue
    end
    respond_to do |format|
      format.js {}
      format.html {redirect_to url_for(@resource_class)}
    end
  end

  # byebug
  unless self.new.respond_to?(:current_user)
    def current_user
      User.new
    end
    helper_method :current_user
  end

  protected
  def validate_user
    # if current_user.present? && (!current_user.manager? || !current_user.has_role?(:owner) || !current_user.has_role?(:client))
    #   if self.class.parent.name != 'My' && params[:format] != "json"
    #     redirect_to my_rfqs_path, notice: t("shared.messages.page_not_found")
    #   end
    # end
  end

  def on_single_resource
  end

  def directory_attrs
    {}
  end

  def _directory_attrs
    default_title    = I18n.t(:"directory.#{@resource_class.name.underscore}.title", default: @resource_class.name.humanize)
    default_subtitle = I18n.t(:"directory.#{@resource_class.name.underscore}.subtitle", default: params[:action])
    {
      icon: "fa-table",
      title:    I18n.t("common.pages.titles.#{@resource_class.name.underscore.pluralize}.#{params[:action]}.title",    default: default_title),
      subtitle: I18n.t("common.pages.titles.#{@resource_class.name.underscore.pluralize}.#{params[:action]}.subtitle", resource: (@resource.respond_to?(:number) ? @resource.number : @resource.name rescue ''), default: default_subtitle)
    }.merge(directory_attrs).merge(@directory_attrs)
  end

  def load_type
    @resource_class = params[:dir_type].classify.constantize
  end

  def resource_collection
    @resource_class.all
  end

  def load_resource
    #byebug
    if params[:id]
      @resource = if params[:restore]
        resource_collection.unscoped.find(params[:id])
      else
        resource_collection.find(params[:id])
      end
    end
  end

  def resource_params(permit = [])

    permit = [permit] unless permit.is_a?(Array)

    #byebug
    _params_to_permit = @resource_class.directory_keys
    _merged_hash = _params_to_permit.inject(Hash.new) {|res, i| i.is_a?(Hash) ? res.deeper_merge(i) : res }

    permit.each do |filter|
      case filter
      when Symbol,String
        _params_to_permit << filter
      when Hash then
#       byebug
        _merged_hash.deeper_merge!(filter)
      end
    end

    _params_to_permit = _params_to_permit.reject {|i| i.is_a?(Hash)}
    _params_to_permit << _merged_hash

    #byebug

    params.require(@resource_class.name.underscore.gsub('/', '_') ).permit(
      _params_to_permit
    )
  end

  def set_title
    if @resource_class.present?
      @page_title = t("common.pages.titles.#{@resource_class.name.pluralize.underscore}.#{params[:action]}.title", default: "АСУ ММП Оборонлогистика")
      @page_subtitle = t("common.pages.titles.#{@resource_class.name.pluralize.underscore}.#{params[:action]}.subtitle", resource: (@resource.respond_to?(:number) ? @resource.number : @resource.name rescue ''), default: '')
      @page_subtitle = nil unless @page_subtitle.present?
    end
  end

  def init_directory
    @directory_attrs = {}
  end

  # def self.directory_for(_class, overrides_hash)
  #   @@_directory_overrides[controller_path] = {} unless @@_directory_overrides[controller_path].is_a?(Hash)
  #   @@_directory_overrides[controller_path][_class] = overrides_hash
  # end


  def self.directory_controls(controls_hash)
    @@_directory_controls[controller_path] = controls_hash
  end

  def add_directory_controls(field, control, params = {})
    @@_directory_controls[controller_path].merge!({field => {control: control, render: true}.merge(params) })
  end

  def remove_directory_controls(*args)
    args.map { |e| @@_directory_controls[controller_path].delete(e) }
  end

  def hide_directory_control(field)
    unless @@_directory_controls[controller_path][field].present?
      @@_directory_controls[controller_path][field] = { control: :text }
    end
    @@_directory_controls[controller_path][field][:render] = false
  end

  def show_directory_control(field)
    if @@_directory_controls[controller_path][field]
      @@_directory_controls[controller_path][field].delete(:render)
    end
  end

  def disable_directory_control(field)
    if @@_directory_controls[controller_path][field]
      @@_directory_controls[controller_path][field].merge!({ disabled: true })
    end
  end

  def enable_directory_control(field)
    if @@_directory_controls[controller_path][field]
      @@_directory_controls[controller_path][field].delete(:disabled)
    end
  end

  def control_for(field)
    @@_directory_controls[controller_path][field] rescue nil
  end

  def directory_buttons(buttons_hash)
    @@_directory_buttons[controller_path] = buttons_hash
  end

  def control_for(field)
    @@_directory_controls[controller_path][field] rescue nil
  end

  def get_directory_buttons
    @@_directory_buttons[controller_path]
  end
end
