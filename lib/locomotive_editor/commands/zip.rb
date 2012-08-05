# require 'rubygems'
# require 'locomotive/models'
# require 'fileutils'
# require 'zip/zip'
#
# module LocomotiveEditor
#
#   module Commands
#
#     class Zip < Base
#
#       def initialize(options)
#         @options = options
#
#         @name = @options[:name]
#
#         if File.exists?('config/site.yml')
#           @name = '.'
#         else
#           raise 'Can not zip a site without a name' if @name.nil?
#         end
#
#         @site = LocomotiveEditor.sites.detect { |s| File.basename(s.folder) == @name || s.name == @name }
#
#         raise "Site not found matching \"#{@name}\"" if @site.nil?
#
#         LocomotiveEditor.site = @site.folder
#
#         @name = File.basename(File.expand_path('.')) if @name == '.'
#       end
#
#       def run!
#         # create the releases folder where the zipfile will be put
#         FileUtils.mkdir_p File.join(Locomotive.site_root, 'releases')
#
#         dst = File.join(Locomotive.site_root, 'releases', "#{@name.downcase}_#{self.version}.zip")
#
#         if File.exists?(dst)
#           if @options[:force]
#             FileUtils.rm(dst)
#           else
#             raise 'Already released a site with the same version. Use --force if needed'
#           end
#         end
#
#         puts "creating...#{File.basename(dst)}"
#
#         self.generate_database_file
#
#         puts "generating scss/sass files"
#
#         self.compile_scss_files
#
#         ::Zip::ZipFile.open(dst, ::Zip::ZipFile::CREATE) do |zipfile|
#           Dir[File.join(Locomotive.site_root, '**/*')].each do |file|
#
#             entry = file.gsub(Locomotive.site_root + '/', '')
#
#             next if entry =~ /^releases/ || entry =~ /^public\/sass/ || %w(compass.rb VERSION).include?(entry)
#
#             next if entry =~ /^config\/(database_archived|site).yml/ || entry =~ /^app\/content_types/ || entry =~ /^data/
#
#             # skip depending on the options
#             next if @options[:without_assets] && entry =~ /^public\//
#
#             next if @options[:without_fonts] && entry =~ /^public\/fonts\//
#
#             next if @options[:without_samples] && entry =~ /^public\/samples\//
#
#             next if @options[:without_images] && entry =~ /^public\/images\//
#
#             puts "...adding #{entry}"
#
#             zipfile.add(entry, file)
#           end
#         end
#
#         # remove the compiled site.yml file
#         FileUtils.rm(File.join(Locomotive.site_root, 'config', 'compiled_site.yml'))
#
#         puts "...done\n\n"
#       end
#
#       def self.help_message
#         """
# Some examples:
#
# * Generate a zip file of your website.
#
#   > locomotive zip -n awesome_website
#
# * Generate a zip file of your website and force the creation if a zip file exists with the same name in the releases/ folder.
#
#   > locomotive zip -n awesome_website --force
#
#   Note:
#     - We suggest you to upgrade the VERSION file to avoid conflicts
#
# * Generate a zip file of your website without the whole public folder
#
#   > locomotive zip -n awesome_website --without-assets
#
# * Generate a zip file of your website without the public/images folder
#
#   > locomotive zip -n awesome_website --without-images
#
# * Generate a zip file of your website without the public/fonts folder
#
#   > locomotive zip -n awesome_website --without-fonts
#
# * Generate a zip file of your website without the public/samples folder
#
#   > locomotive zip -n awesome_website --without-samples"""
#       end
#
#       protected
#
#       def compile_scss_files
#         return unless File.directory?(File.join(Locomotive.site_root, 'public', 'sass'))
#
#         if File.exists?(File.join(Locomotive.site_root, 'compass.rb'))
#           `compass compile #{Locomotive.site_root} --config=#{Locomotive.site_root}/compass.rb --force`
#         else
#           `sass --update #{Locomotive.site_root}/public/sass:#{Locomotive.site_root}/public/stylesheets`
#         end
#       end
#
#       def generate_database_file
#         File.open(File.join(Locomotive.site_root, 'config', 'compiled_site.yml'), 'w') do |f|
#           f.write(yaml(Locomotive::Models::Base.source))
#         end
#       end
#
#       def version
#         if File.exists?(File.join(Locomotive.site_root, 'VERSION'))
#           File.read(File.join(Locomotive.site_root, 'VERSION'))
#         else
#           '0.0.1'
#         end
#       end
#
#     end
#
#   end
#
# end