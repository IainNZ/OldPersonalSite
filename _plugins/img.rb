module Jekyll
  class RenderTimeTag < Liquid::Tag

    def initialize(tag_name, args, tokens)
      super
      @args = args
    end

    def render(context)
      spl = @args.strip.split(/\s+/)
      url = spl[0]
      cap = spl.slice(1..-1).join(" ")
      "<div class=\"photo\"><img src=\"#{url}\" alt=\"#{cap}\"><p class=\"caption\">#{cap}</p></div>"
    end
  end
end

Liquid::Template.register_tag('img', Jekyll::RenderTimeTag)
