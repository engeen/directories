class String
  def to_url
    self.underscore.gsub(/[\/\\]/, '_')
  end
end
