
module DA_HTML

  module SPAN

    macro span(*args, **attrs, &blok)
      io.render_tag!("span") {
        {% unless args.empty? %}
          span_id_class {{*args}}
        {% end %}
        {% for k,v in attrs %}
          span_{{k}}({{v}})
        {% end %}

        span_render {
          {{blok.body}}
        }
      }
    end # === macro span

    def span_id_class(s)
      io.render_attr!("id_class", s)
    end # === def span_id_class

    def span_render
      yield
    end # === def span_render

  end # === module SPAN

end # === module DA_HTML