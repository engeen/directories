module DirectoryOverrides
  extend ActiveSupport::Concern

  def edit_overrides_for(_class)
      #byebug
      self.class.directory_overrides[controller_path][_class][:edit] rescue nil
  end

  def create_overrides_for(_class)
      #byebug
      (self.class.directory_overrides[controller_path][_class][:create] rescue edit_overrides_for(_class)) rescue nil
  end

  def display_overrides_for(_class)
      #byebug
      self.class.directory_overrides[controller_path][_class][:display] rescue nil
  end

  def buttons_overrides_for(klass)
    self.class.buttons_overrides[controller_path][klass] rescue nil
  end

  included do
    helper_method :edit_overrides_for
    helper_method :create_overrides_for
    helper_method :display_overrides_for
    helper_method :buttons_overrides_for

    class << self
      def directory_overrides
        @@directory_overrides ||= {}
      end
      def buttons_overrides
        @@buttons_overrides ||= {}
      end

      def directory_for(_class, overrides_hash)
    		directory_overrides[controller_path] = {} unless directory_overrides[controller_path].is_a?(Hash)
    		directory_overrides[controller_path][_class] = overrides_hash
    	end
    end

    protected
    def directory_buttons_for(klass, overrides_hash)
      self.class.buttons_overrides[controller_path] = {} unless self.class.buttons_overrides[controller_path].is_a?(Hash)
      self.class.buttons_overrides[controller_path][klass] = overrides_hash
    end
  end
end
