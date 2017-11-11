

class Attrs_Spec_HTML
  include DA_HTML::DSL::SPAN
  include DA_HTML::DSL::P
  include DA_HTML::DSL::DIV
  include DA_HTML::DSL::TEXT

  getter :io
  def initialize
    @io = DA_HTML::IO_HTML.new
  end # === def initalize

  def self.render
    h = new
    with h yield
    h.io.to_html
  end

  macro my_tag(**attrs, &blok)
    io.write_tag("my_tag") {
      {% for k, v in attrs %}
        io.write_attr "{{k.id}}", my_tag_{{k.id}}({{v}})
      {% end %}
      io.write_content {
        {{blok.body}}
      }
    }
  end # === macro my_tag

  def my_tag_hello(s : String)
    s
  end # === def my_tag_hello

  def to_html
    @io.to_html
  end # === def to_html
end # === class HTML

describe "io.write_attr" do
  it "escapes values of attributes" do
    actual = Attrs_Spec_HTML.render {
      my_tag(hello: "<joe>") { }
    }
    should_eq actual, "<my_tag hello=\"&#x3c;joe&#x3e;\"></my_tag>"
  end # === it "escapes values of attributes"

  it "allows single attributes: <input required ...>" do
    actual = Attrs_Spec_HTML.render {
      io.write_closed_tag("input", {"maxlength", "10"}, {"required"})
    }
    should_eq actual, %(<input maxlength="10" required>)
  end # === it "allows single attributes: <input required ...>"
end # === desc ":attrs"
