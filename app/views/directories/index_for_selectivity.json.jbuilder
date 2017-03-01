def combined_attrs(resource_class, fields = [])
	(resource_class.column_names.map {|c| c.to_sym} + resource_class.directory_fields + fields + resource_class.unload_fields).uniq
end


def do_nest(resource,field,json)
	if field.is_a?(Hash)
		json.set! field.keys.first do
			combined_attrs(resource.class.reflect_on_association(field.keys.first).class_name.constantize, field[field.keys.first]).each do |subfield|
				do_nest(resource.send(field.keys.first), subfield, json)
			end
		end
	else
		json.set! field, ((resource.send(field) rescue "" )||"-#{resource.id}-")
	end
end

json.array! @resources do |resource|
	combined_attrs(resource.class).each do |field|
		do_nest(resource, field, json)
	end
end
