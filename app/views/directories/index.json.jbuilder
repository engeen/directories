def combined_attrs(resource_class, fields = [])
	(resource_class.column_names.map {|c| c.to_sym} + resource_class.directory_fields + fields + resource_class.unload_fields).uniq - (resource_class.dont_unload_fields)
end


def do_nest(resource,field,json)
	if resource.present?
		if field.is_a?(Hash)
			if resource.class.reflect_on_association(field.keys.first)
				json.set! field.keys.first do
					combined_attrs(resource.class.reflect_on_association(field.keys.first).class_name.constantize, field[field.keys.first]).each do |subfield|
						do_nest(resource.send(field.keys.first), subfield, json)
					end
				end
			else
				json.partial! 'directories/index_item', resource: resource, field: field
			end
		else
			#byebug
			if !params.has_key?(:no_templates) && directory_template_exist?("s_item_#{field}", locals: { resource: resource }, formats: [:html])
				json.set! field do
					json.set! :data, ((resource.send(field) rescue "" )||"")
					json.set! :html, directory_render("s_item_#{field}", locals: { resource: resource }, formats: [:html])
				end
			else
				json.set! field, ((resource.send(field).to_s rescue "" )||"")
			end
		end
	else
		""
	end
end

json.set! :recordsTotal, @resources.try(:total_count) || @resources.count
json.set! :recordsFiltered, @resources.try(:total_count) || @resources.count
json.data do
	json.array! @resources do |resource|
		combined_attrs(@resource_class).each do |field|
			do_nest(resource, field, json)
		end
	end
end
