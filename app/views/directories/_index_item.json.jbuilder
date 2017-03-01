if field.is_a?(Hash) && field.has_key?(:template)
  json.set! field.keys.first do
    json.set! :data, ((resource.send(field.keys.first) rescue "" )||"")
    if field[:template].present?
      json.html directory_render field[:template], locals: { resource: resource }, formats: [:html]
    else
      partial = find_render_template(field, {})
      json.html render partial: partial, locals: { resource: resource, field: field }, formats: [:html,:json, :js]
    end
  end
else
  if false #partial = find_render_template(field, {})
    json.set! field.keys.first do
      json.set! :data, ((resource.send(field.keys.first) rescue "" )||"")
      json.html render partial: partial, locals: { resource: resource, field: field }, formats: [:html,:json, :js]
    end
  else
    json.set! field, ((resource.send(field) rescue "" )||"")
  end
end
