require "has_wysiwyg_content/version"
require "has_wysiwyg_content/action_view_helper"

module HasWysiwygContent
  OPTIONS = {
    :url_regexp => nil
  }

  module Extensions

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def has_wysiwyg_content(*fields)
        include HasWysiwygContent::Extensions::InstanceMethods

        const_set('WYSIWYG_FIELDS', fields.map(&:to_s))

        before_save {|o| cleanse_wysiwyg_content }

        define_method("self.class.wysiwyg_attributes") { (self.class.column_names & fields.map(&:to_s)) }
        class_eval <<-"EOV"
          class << self
            def wysiwyg_attributes
              column_names & WYSIWYG_FIELDS
            end
          end
        EOV
      end
    end 

    module InstanceMethods
      def cleanse_wysiwyg_content
        self.class.wysiwyg_attributes.each do |field|
          regexp = HasWysiwygContent::OPTIONS[:url_regexp]
          send("#{field}=", send(field).gsub(regexp, '\\1')) unless send(field).blank? || regexp.nil?
        end
      end

      def update_wysiwyg_attributes(params = {})
        wysiwyg_params = params.delete_if{|k,v| !self.class.wysiwyg_attributes.include? k.to_s}
        update_attributes(wysiwyg_params)
      end
    end

  end
end

ActiveRecord::Base.send :include, HasWysiwygContent::Extensions
