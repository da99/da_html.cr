
module DA_HTML

  alias JS_Document = Deque(Node)

  module Javascript

    extend self

    def template_tags(doc : Deque(Node))
      bag = Deque(Node).new
      doc.each { |n|
        if n.is_a?(Tag) && n.tag_name == "template"
          bag.push n
          next
        end

        if n.is_a?(Tag)
          bag.concat template_tags(n.children)
          next
        end

        next
      }
      bag
    end # === def

    def to_javascript(nodes : Deque(Node))
      io = IO::Memory.new
      template_tags(nodes).each { |n|
        to_javascript(io, n)
      }
      io.to_s
    end # def

    def to_javascript(io, node : Node)
      case node
      when Comment
        :ignore

      when Text
        io << "\nio += #{node.to_html.inspect};" unless node.empty?

      when Tag
        case node.tag_name

        when "each"
          each_to_javascript(io, node)

        when "each-in"
          each_in_to_javascript(io, node)

        when "var"
          var_to_javascript(io, node)

        when "template"
          template_to_javascript(io, node)

        else
          tag_to_javascript(io, node)

        end
      end # case
      io
    end # def

    def template_to_javascript(io, tag : Tag)
      io << '\n' << %[
        function #{tag.attributes["id"]}(data) {
          let io = "";
      ].strip
      tag.children.each { |x| to_javascript(io, x) }
      io << "\nreturn io;\n}"
      io
    end # === def

    def tag_to_javascript(io, tag : Tag)
      io << %[\nio += #{DA_HTML.open_tag(tag).gsub('"', %[\\"]).inspect};]
      unless tag.void?
        tag.children.each { |x| to_javascript(io, x) }
        io << %[\nio += #{DA_HTML.close_tag(tag).inspect};]
      end
    end # === def

    def var_to_javascript(io, node)
      text = node.children.first
      case text
      when Text
        io << %[\nio += #{text.tag_text}.toString();]
        io
      else
        raise Exception.new("Expecting text for node: #{node.inspect}")
      end
    end # === def

    def each_to_javascript(io, node)
      coll, _as, var = node.attributes.keys
      io << '\n' << %[
        for (let #{i coll} = 0, #{length coll} = #{coll}.length; #{i coll} < #{length coll}; ++#{i coll}) {
          let #{var} = #{coll}[#{i coll}];
      ].strip

      node.children.each { |x| to_javascript(io, x) }

      io << "\n}"
      io
    end # def

    def each_in_to_javascript(io, node)
      coll, _as, key, var = node.attributes.keys.join(' ').split(/\ |,/)
      io << '\n' << %[
       for (let #{i(coll)} = 0, #{keys(coll)} = Object.keys(#{coll}), #{length(coll)} = #{keys coll}.length; #{i coll} < #{length coll}; ++#{i(coll)}) {
         let #{key} = #{keys coll}[#{i coll}];
         let #{var} = #{coll}[#{key}];
      ].strip
      node.children.each { |x| to_javascript(io, x) }
      io << "\n}"
      io
    end # === def

    # =============================================================================
    # Instance:
    # =============================================================================

    def var_name(name : String)
      name.gsub(/[^a-z\_0-9]/, "_")
    end

    def i(name : String)
      "_#{var_name name}__i"
    end

    def keys(name : String)
      "_#{var_name name}__keys"
    end

    def length(name : String)
      "_#{var_name name}__length"
    end

    def var_name(x : String)
      x.gsub(/[^a-zA-Z0-9\-]/, "_")
    end

    def let(x : String, y : String)
      js_io << spaces << "let " << var_name(x) << " = " << y << ";\n"
      self
    end # === def

    def print_line(x : String)
      js_io << spaces << x << ";\n"
      self
    end # === def

    def print_block(s : String)
      print "#{s} {\n"
      indent {
        yield
      }
      print "} // #{s}\n"
    end

    def _print(x : Node)
      case
      when x.tag_name == "negative"

          options = Tag_Options.new(x)
          to_crystal("negative", options)
          print_block("if (#{options.name} < 0)") {
            if options.as_name?
              let(options.as_name.not_nil!, "#{options.name}")
            end
            print_children(x)
          }
          return

      when x.tag_name == "zero"

          options = Tag_Options.new(x)
          to_crystal("zero", options)
          print_block("if (#{options.name} === 0)") {
            if options.as_name?
              let(options.as_name.not_nil!, options.name)
            end
            print_children(x)
          }
          return

      when x.tag_name == "positive"

          options = Tag_Options.new(x)
          to_crystal("positive", options)
          print_block("if (#{options.name} > 0)") {
            if options.as_name?
              let(options.as_name.not_nil!, options.name)
            end
            print_children(x)
          }
          return

      when x.tag_name == "empty"
          options = Tag_Options.new(x)
          to_crystal("empty", options)
          print_block("if (#{options.name}.length === 0)") {
            if options.as_name?
              let(options.as_name.not_nil!, options.name)
            end
            print_children(x)
          }
          return

      when x.tag_name == "not-empty"
          options = Tag_Options.new(x)
          to_crystal("not-empty", options)
          print_block("if (#{options.name}.length > 0)") {
            if options.as_name?
              let(options.as_name.not_nil!, options.name)
            end
            print_children(x)
          }
          return

      when x.print_in_html?
        append_to_js "<#{x.tag_name} #{x.attributes.map { |k, v| "#{k}=\"#{v}\"" }.join ' '}>".inspect
        indent {
          print_children(x)
        }
        append_to_js("</#{x.tag_name}>".inspect) if x.end_tag?

      end # case

    end # def print


  end # === struct Javascript

end # === module DA_HTML