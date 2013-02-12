require 'test/unit'
require 'rubygems'
require 'has_wysiwyg_content'

class TestHasWysiwygContentHelper < ActiveSupport::TestCase
  include ActionView::Context
  include ActionView::Helpers
  include HasWysiwygContent::TagHelper

  def test_simple_string
    assert_equal "simple", wysiwyg("simple")
  end

  def test_intact_yield_if_no_block_given
    assert_equal "start {{yield}} end", wysiwyg("start {{yield}} end")
  end

	def test_yield_to_the_block_if_yield_provided_and_block_is_given
    result = wysiwyg("start {{yield}} end") { "block" }
    assert_equal "start block end", result
  end

	def test_append_the_block_if_no_yield_provided_and_block_is_given
    result = wysiwyg("start end") { "block" }
    assert_equal "start endblock", result
  end

	def test_not_append_the_block_if_yield_provided_and_block_is_given
    result = wysiwyg("start {{yield}} end") { "block" }
    assert_equal "start block end", result
  end

	def test_not_quelch_obj_meth_if_no_match_is_found
    result = wysiwyg("start {{obj.meth}} end")
    assert_equal "start {{obj.meth}} end", result
  end

	def test_replace_obj_meth_if_match_is_found
    obj = Object.new
    def obj.meth; 'foobar'; end
    result = wysiwyg("start {{obj.meth}} end", :obj => obj)
    assert_equal "start foobar end", result
  end

	def test_handle_mailto_philip_pjkh_com
    assert_equal "start #{mail_to 'philip@pjkh.com', nil, :encode => :javascript} end", 
                 wysiwyg("start {{mailto:philip@pjkh.com}} end")
  end

	def test_handle_mailto_philip_pjkh_com_click_me
    assert_equal "start #{mail_to 'philip@pjkh.com', 'click me', :encode => :javascript} end", 
                 wysiwyg("start {{mailto:philip@pjkh.com:click me}} end")
  end

	def test_should_handle_spaces_in_mailto
    assert_equal "start #{mail_to 'philip@pjkh.com', 'click me', :encode => :javascript} end",
                 wysiwyg("start {{mailto   :   philip@pjkh.com   :   click me}} end")
  end

end
