module Stateable
  extend ActiveSupport::Concern
  # include Notifiable

  @@requires_comments_for = []
  @@modal_options = {}

  included do
    # after_action :notify_state, only: :state

    def self.commented_states(states = [], options = {})
      @@modal_options = options
      @@requires_comments_for = states.map { |s| s.to_s }
    end

    protected
    # def notify_state
    #   change = @resource.audits.where(action: :update).last.try(:audited_changes).try(:[], "state")
    #   if change.present?
    #     Notification.includes(:roles).where(name: "#{@resource.class.name.underscore}_#{change.last}").each { |notification| notify(notification) }
    #   end
    # end
  end

  def state
    unless @resource
      load_resource
    end
    if @resource && @resource.respond_to?(params[:state])
      # byebug
      @resource.send("#{params[:state]}!")
      ActiveRecord::Base.transaction do
        begin
          # @resource.save!
          flash.now[:success] = t("#{@resource.class.name.underscore.pluralize}.messages.transitions.#{params[:state]}.success", default: "Статус успешно изменен")
        rescue Exception => e
          flash.now[:error] = t("#{@resource.class.name.underscore.pluralize}.messages.transitions.#{params[:state]}.fail", default: "Не удалось изменить статус")
          raise ActiveRecord::Rollback
        end
      end
    end
    @requires_comments_for = @@requires_comments_for
    @modal_options = @@modal_options

    respond_to do |format|
      format.js { render "#{params[:scope].present? ? (params[:scope] + "/#{@resource.class.name.to_url}_") : ''}state" }
    end
  end
end
