require "minitest/autorun"

require "fakeweb"
require "mocha"
require "oso"

FakeWeb.allow_net_connect = false

class TestOso < MiniTest::Unit::TestCase
  def setup
    FakeWeb.clean_registry
    ENV["OSO_URL"] = nil
  end

  def test_initialize
    assert_equal URI.parse("http://localhost:9292/"), Oso.new.url

    ENV["OSO_URL"] = "http://foo/"

    assert_equal URI.parse("http://foo/"), Oso.new.url
    assert_equal URI.parse("http://foo/"), Oso.new("http://foo/").url
    assert_equal URI.parse("http://foo/"), Oso.new("http://foo").url
    assert_equal URI.parse("http://foo/"), Oso.new("foo").url
  end

  def test_self_instance
    assert_same Oso.instance, Oso.instance
  end

  def test_self_shorten
    Oso.instance.expects(:shorten).with("foo").returns "bar"
    assert_equal "bar", Oso.shorten("foo")
  end

  def test_shorten
    FakeWeb.register_uri :post, "http://example.org/",
      :body => "http://example.org/1", :status => 201

    oso = Oso.new "example.org"

    assert_equal "http://example.org/1", oso.shorten("whatever")
  end

  def test_shorten_bad
    FakeWeb.register_uri :post, "http://example.org/",
      :body => "No luck.", :status => 404

    oso = Oso.new "example.org"

    assert_raises Oso::Error do
      oso.shorten "blah"
    end
  end
end
