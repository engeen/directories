module AASM
  def available_steps
    aasm.events.map(&:name).reject { |step| step unless self.send("may_#{step}?") }
  end

  def state_t
    I18n.t("#{self.class.name.underscore.pluralize}.states.#{state}")
  end
end
