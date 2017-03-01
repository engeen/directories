module Directory
  extend ActiveSupport::Concern
  include Searchable

  included do
    if self.respond_to?(:table_name) && ActiveRecord::Base.connection.table_exists?(self.table_name) && ActiveRecord::Base.connection.column_exists?(self.table_name, :deleted_at)
      acts_as_paranoid
    end

  	@@_directory_fields ||= {}

    def display_value
      self.number rescue self.name rescue self.to_param
    end

    class << self
      def directory(opts = [])
        @@_directory_fields[name] = {}
        if opts.is_a?(Hash)
          opts.keys.each do |key|
            opts[key].each do |p|
              @@_directory_fields[name][key] ||= []
              @@_directory_fields[name][key].push p
            end
          end
        else
          opts.each do |param|
            @@_directory_fields[name] ||= {}
            @@_directory_fields[name][:display] ||= []
            @@_directory_fields[name][:display].push param
            @@_directory_fields[name][:edit] ||= []
            @@_directory_fields[name][:edit].push param
          end
        end
      end

      def push_to_directory(param, field)
        @@_directory_fields[name][param].push(field)
      end

      def directory_fields
        @@_directory_fields[name][:display] || []
      end

      def dont_unload_fields
        @@_directory_fields[name][:dont_unload] || []
      end

      def unload_fields
        @@_directory_fields[name][:unload] || []
      end

      def edit_directory_fields
        @@_directory_fields[name][:edit] || []
      end


      def create_directory_fields
        ( @@_directory_fields[name][:create] || @@_directory_fields[name][:edit] ) ||  []
      end

      def directory_nested
        @@_directory_fields[name][:nested] || []
      end


      def directory_show
        @@_directory_fields[name][:show] || []
      end

      def directory_keys
        self.get_belongs_to_keys(edit_directory_fields, self)
      end
    end


    protected
    def self.get_belongs_to_keys(_fields, __class)
      f =  _fields.map do |_f|
         if _f.is_a?(Hash)
          {
            :"#{_f.keys.first}_attributes"  =>  self.get_belongs_to_keys( _f[_f.keys.first] , __class.reflect_on_association(_f.keys.first).class_name.constantize )
          }
         else
          if __class.reflect_on_association(_f)
            :"#{_f.to_s}_id"
          else
            _f
          end
        end
      end
      # ассоциативные аттрибуты разбитые на части некорректно пермитятся А.В.Н.
      hashes = []
      f = f.map {|k| k.is_a?(Hash) ? hashes.push(k) && nil : k}.compact
      f.push(hashes.reduce { |a,b|  a.keys.first == b.keys.first ? {a.keys.first => (a[a.keys.first] + b[b.keys.first]).compact } : a })
      f
    end
  end
end
