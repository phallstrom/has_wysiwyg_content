require 'test/unit'
require 'rubygems'
require 'active_record'
require 'action_controller'
require 'has_wysiwyg_content'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :widgets do |t|
        t.column :content, :text
      end
    end
  end
end

def teardown_db
  silence_stream(STDOUT) do
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end
end

class Widget < ActiveRecord::Base
  has_wysiwyg_content :content
  #def self.table_name() "widgets" end
end

################################################################################

class TestHasWysiwygContent < ActiveSupport::TestCase
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::JavaScriptHelper
  include HasWysiwygContent::TagHelper

  def setup
    setup_db
    @widget = Widget.new(
      :content => 'English. {{some_var.foo}}. {{invalid.foo}} {{{{mailto:philip@pjkh.com}}. <a href="http://www.pjkh.com/foo">click</a>. <a href=\'http://www.pjkh.com/bar\'>me</a>. The End.'
    )
  end

  def teardown
    teardown_db
  end

  def test_responds_to_update_wysiwyg_attributes
    assert_respond_to @widget, :update_wysiwyg_attributes
  end

  def test_saved_content_is_not_cleansed_by_default
    HasWysiwygContent::OPTIONS[:url_regexp] = nil
    orig_content = @widget.content.dup
    @widget.save!
    assert_equal orig_content, @widget.content
  end

  def test_saved_content_is_cleansed_if_regexp_provided
    HasWysiwygContent::OPTIONS[:url_regexp] = %r!http://www.pjkh.com!
    @widget.save!
    assert_equal 'English. {{some_var.foo}}. {{invalid.foo}} {{{{mailto:philip@pjkh.com}}. <a href="/foo">click</a>. <a href=\'/bar\'>me</a>. The End.', @widget.content
  end

  def test_wysiwyg_fields_only_contains_table_fields
    assert_equal %w[content], Widget.wysiwyg_attributes
  end

  #
  # Testing the helper...
  #

  def test_parsed_content_encodes_emails
    assert_no_match /philip@pjkh.com/, wysiwyg(@widget.content)
  end

  def test_parsed_content_converts_valid_substitutions
    @my_var = Object.new
    def @my_var.foo; "VALUE_OF_MY_VAR"; end
    assert_no_match /\{\{some_var.foo\}\}/, wysiwyg(@widget.content, :some_var => @my_var)
    assert_match /VALUE_OF_MY_VAR/, wysiwyg(@widget.content, :some_var => @my_var)
  end

  def test_parsed_content_does_not_convert_nonexistent_substitutions
    assert_match /\{\{invalid.foo\}\}/, wysiwyg(@widget.content)
  end

end

