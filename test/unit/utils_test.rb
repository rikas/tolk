require 'test_helper'
require 'fileutils'

class UtilsTest < ActiveSupport::TestCase
  def test_flat_hash
    data = {'home' => {'hello' => 'hola', 'sidebar' => {'title' => 'something'}}}
    result = Tolk::Utils.flat_hash(data)

    assert_equal 2, result.keys.size
    assert_equal ['home.hello', 'home.sidebar.title'], result.keys.sort
    assert_equal ['hola', 'something'], result.values.sort
  end

  def test_filter_out_i18n_keys
    flat_hash = {
      'i18n' => 'To be filtered',
      'i18n.test' => 'Also filtered',
      'hello' => 'world'
    }

    data = Tolk::Utils.filter_out_i18n_keys(flat_hash)

    assert_nil data['i18n']
    assert_nil data['i18n.test']
    assert_equal data['hello'], 'world'
  end

  def test_filter_out_ignored_keys
    flat_hash = {
      'home' => 'hello',
      'ignored' => 'This will be ignored',
      'nested.ignored' => 'This will also be ignored',
      'nested.not_ignored' => 'hi'
    }

    Tolk.config.ignore_keys = %w[ignored nested.ignored]

    data = Tolk::Utils.filter_out_ignored_keys(flat_hash)

    assert_nil data['ignored']
    assert_nil data['nested.ignored']
    assert_equal data['home'], 'hello'
    assert_equal data['nested.not_ignored'], 'hi'
  end
end
