%w(helpers base token theme_asset content_asset content_type content_entry snippet page site).each do |name|
  require File.join(File.dirname(__FILE__), "api/#{name}.rb")
end