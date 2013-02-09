module HasWysiwygContent
  module TagHelper

    def wysiwyg(field, substitutions = {}, &block)
      block_captured = false
      field.to_s.gsub(/\{\{(.*?)\}\}/) do |match| 
        str = $1
        if str =~ /mailto\s*:\s*([^:\s]+)(?:\s*:\s*(.+))?/
          mail_to($1, $2, :encode => :javascript) 
        elsif str == 'yield' && block_given?
          block_captured = true
          capture(&block)
        else
          var, method = str.split('.', 2)
          substitutions.key?(var.to_sym) ? substitutions[var.to_sym].send(method) : match
        end
      end + ( block_given? && !block_captured ? capture(&block) : '' )
    end

  end
end

ActionView::Base.send :include, HasWysiwygContent::TagHelper
