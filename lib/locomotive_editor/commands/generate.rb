require 'faker'

module LocomotiveEditor

  module Commands

    class Generate < Base

      def initialize(options, content_type_options)
        @options = options

        self.set_site

        raise 'You have to specify the content type name, ex: locomotive generate -n my_site my_projects' if content_type_options.empty?

        @content_type_options = parse_options(content_type_options)
      end

      def run!
        filename = @content_type_options[:slug]

        # generate the data file

        puts "generating data/#{filename}.yml"

        filepath = File.join(LocomotiveEditor.site_root, 'data', "#{filename}.yml")

        FileUtils.mkdir_p File.dirname(filepath)

        File.open(filepath, 'w') do |f|
          f.write(yaml(self.generate_random_data))
        end

        # generate the content type file

        puts "generating app/content_types/#{filename}.yml"

        filepath = File.join(LocomotiveEditor.site_root, 'app', 'content_types', "#{filename}.yml")

        FileUtils.mkdir_p File.dirname(filepath)

        raise 'The content type already exists, use the --force option to bypass this message' if File.exists?(filepath) && @options[:force] == false

        @content_type_options[:fields].collect(&:stringify_keys!)

        File.open(filepath, 'w') do |f|
          f.write(yaml(@content_type_options))
        end

        puts "\n\nYour content_type named \"#{@content_type_options[:name]}\" has been created with success.\n\n"
      end

      def self.help_message
        """
Some examples:

* Generate a content type named projects. By default, 2 fields will be added: title and description

  > locomotive generate -n awesome_website projects

  Note:
    - a file called \"projects.yml\" will be created and put in the app/content_types folder.

* Generate a content type with n fields

  > locomotive generate -n awesome_website projects title:string description:text

  > locomotive generate -n awesome_website projects title:string image:file

  > locomotive generate -n awesome_website projects title:string author:belongs_to:people featured:boolean

  > locomotive generate -n awesome_website projects title:string author:belongs_to:people featured:boolean related_projects:has_many:projects

  Notes:
    - here is the list of the available field types:
      string, text, select, boolean, date, file, has_one, has_many

    - the script also generates a data file that you can update. Check the data/ folder out."""
      end

      protected

      def generate_random_data
        content_type_name = @content_type_options[:label_field_name]
        collection  = []

        4.times do |i|
          highlighted_field_value = "Item ##{i + 1}"

          fields = { '_permalink' => "item-#{i+1}" }

          @content_type_options[:fields].each do |hash|
            name, attributes = hash.keys.first, hash.values.first

            next if name == content_type_name

            value = (case attributes[:type]
            when 'string'               then Faker::Lorem.sentence
            when 'text'                 then Faker::Lorem.paragraph
            when 'select'               then Faker::Lorem.words(1)
            when 'boolean'              then rand(10) % 3 == 0
            when 'file'                 then "'/samples/#{content_type_name}/yourfile.png' # do not forget to put your files under /samples/#{content_type_name}"
            when 'date'                 then Date.today
            when 'belongs_to'           then nil
            when 'has_many'             then []
            when 'many_to_many'         then []
            end)

            fields[name] = value
          end

          collection << { highlighted_field_value => fields }
        end

        collection
      end

      def parse_options(options)
        name = options.delete_at(0)
        slug = name.slugify

        fields = options.collect do |f|
          field_name, field_type, field_target = f.index(':') ? f.split(':') : [f, nil, nil]

          unless ['string', 'text', 'select', 'boolean', 'date', 'file', 'belongs_to', 'has_many', 'many_to_many'].include?(field_type)
            raise "[Warning] unknown or empty field type \"#{field_type}\""
          end

          { field_name => { :label => field_name.humanize, :type => field_type, :hint => 'Fill the text here', :required => true } }.tap do |hash|
            hash[field_name].merge!(:class_name => field_target) if field_target
          end
        end

        if fields.empty?
          fields << { :title => { :label => 'Title', :type => 'string', :hint => 'Fill the text here' } }
          fields << { :description => { :label => 'Description', :type => 'text', :hint => 'Fill the text here' } }
        end

        label_field_name = fields.first.keys.first

        # first field always required
        fields.first.values.first[:required] = true

        {
          :name                       => name,
          :description                => 'Fill the text here',
          :slug                       => slug,
          :label_field_name           => label_field_name,
          :fields                     => fields,
          :public_submission_enabled  => false,
          :order_by                   => 'manually'
        }
      end

    end

  end

end