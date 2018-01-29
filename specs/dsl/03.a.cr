
describe "a tag" do
  it "sanitizes javascript :href values" do
    actual = A_Spec_HTML.new.render {
      a(href: "javascript://a") { "my page" }
    }
    should_eq actual, %(<a href="#invalid">my page</a>)
  end # === it "sanitizes javascript :href values"

  it "allows :id attribute" do
    actual = A_Spec_HTML.new.render {
      a("#main", href: "/page") { "the page" }
    }
    should_eq actual, %(<a id="main" href="/page">the page</a>)
  end # === it "allows :id attribute"
end # === desc "a tag"
