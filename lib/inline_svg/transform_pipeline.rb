require 'nokogiri'
require 'loofah'

module InlineSvg
  module TransformPipeline
    module Transformations
      class Transformation
        def self.create_with_value(value)
          self.new(value)
        end

        attr_reader :value

        def initialize(value)
          @value = value
        end

        def transform(*)
          raise "#transform should be implemented by subclasses of #{self.class}"
        end
      end

      class NoComment < Transformation
        def transform(doc)
          doc = Loofah::HTML::DocumentFragment.parse(doc.to_html)
          doc.scrub!(:strip)
        end
      end

      class ClassAttribute < Transformation
        def transform(doc)
          doc = Nokogiri::XML::Document.parse(doc.to_html)
          svg = doc.at_css 'svg'
          svg['class'] = value
          doc
        end
      end

      class Title < Transformation
        def transform(doc)
          doc = Nokogiri::XML::Document.parse(doc.to_html)
          node = Nokogiri::XML::Node.new('title', doc)
          node.content = value
          doc.at_css('svg').add_child(node)
          doc
        end
      end

      class Description < Transformation
        def transform(doc)
          doc = Nokogiri::XML::Document.parse(doc.to_html)
          node = Nokogiri::XML::Node.new('desc', doc)
          node.content = value
          doc.at_css('svg').add_child(node)
          doc
        end
      end

      class NullTransformation < Transformation
        def transform(doc)
          doc
        end
      end

      def self.all_transformations
        {nocomment: NoComment, class: ClassAttribute, title: Title, desc: Description}
      end

      def self.lookup(transform_params)
        transform_params.map do |key, value|
          all_transformations.fetch(key, NullTransformation).create_with_value(value)
        end
      end
    end

    def self.generate_html_from(svg_file, transform_params)
      document = Nokogiri::XML::Document.parse(svg_file)
      Transformations.lookup(transform_params).reduce(document) do |doc, transformer|
        transformer.transform(doc)
      end.to_html
    end
  end
end