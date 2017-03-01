json.extract! @resource_class.column_names+@resource_class.directory_fields.map { |f| f.to_s }
