# frozen_string_literal: true

module Alchemy
  # Provides a collection of block-level helpers, allowing for a much more
  # concise way of writing element view/editor partials.
  #
  module ElementsBlockHelper
    # Base class for our block-level helpers.
    #
    class BlockHelper
      attr_reader :helpers
      attr_reader :opts

      def initialize(helpers, opts = {})
        @helpers = helpers
        @opts = opts
      end

      def element
        opts[:element]
      end
    end

    # Block-level helper class for element views.
    #
    class ElementViewHelper < BlockHelper
      # Renders one of the element's ingredients.
      #
      # If the element uses +ingredients+ it renders the ingredient record.
      #
      def render(name, options = {}, html_options = {})
        renderable = element.ingredient_by_role(name)
        return if renderable.nil?

        helpers.render(
          renderable.as_view_component(
            options: options,
            html_options: html_options
          )
        )
      end

      # Returns the value of one of the element's ingredients.
      #
      def value(name)
        element.value_for(name)
      end

      # Returns true if the given ingredient has a value.
      #
      def has?(name)
        element.has_value_for?(name)
      end

      # Return's the ingredient record by given role.
      #
      def ingredient_by_role(role)
        element.ingredient_by_role(role)
      end
    end

    # Block-level helper for element views. Constructs a DOM element wrapping
    # your content element and provides a block helper object you can use for
    # concise access to Alchemy's various helpers.
    #
    # === Example:
    #
    #   <%= element_view_for(element) do |el| %>
    #     <%= el.render :title %>
    #     <%= el.render :body %>
    #     <%= link_to "Go!", el.ingredient(:target_url) %>
    #   <% end %>
    #
    # You can override the tag, ID and class used for the generated DOM
    # element:
    #
    #   <%= element_view_for(element, tag: 'span', id: 'my_id', class: 'thing') do |el| %>
    #      <%- ... %>
    #   <% end %>
    #
    # If you don't want your view to be wrapped into an extra element, simply set
    # `tag` to `false`:
    #
    #   <%= element_view_for(element, tag: false) do |el| %>
    #      <%- ... %>
    #   <% end %>
    #
    # @param [Alchemy::Element] element
    #   The element to display.
    # @param [Hash] options
    #   Additional options.
    #
    # @option options :tag (:div)
    #   The HTML tag to be used for the wrapping element.
    # @option options :id (the element's dom_id)
    #   The wrapper tag's DOM ID.
    # @option options :class (the element's name)
    #   The wrapper tag's DOM class.
    # @option options :tags_formatter
    #   A lambda used for formatting the element's tags (see Alchemy::ElementsHelper::element_tags_attributes). Set to +false+ to not include tags in the wrapper element.
    #
    def element_view_for(element, options = {})
      if options[:id].nil?
        Alchemy::Deprecation.warn <<~WARN
          Relying on an implicit DOM id in `element_view_for` is deprecated. Please provide an explicit `id` if you actually want to render an `id` attribute on the #{element.name} element wrapper tag.
        WARN
      end

      if options[:class].nil?
        Alchemy::Deprecation.warn <<~WARN
          Relying on an implicit CSS class in `element_view_for` is deprecated. Please provide an explicit `class` for the #{element.name} element wrapper tag.
        WARN
      end

      options = {
        tag: :div,
        id: (!!options[:id]) ? options[:id] : element.dom_id,
        class: element.name,
        tags_formatter: ->(tags) { tags.join(" ") }
      }.merge(options)

      # capture inner template block
      output = capture do
        yield ElementViewHelper.new(self, element: element) if block_given?
      end

      # wrap output in a useful DOM element
      if (tag = options.delete(:tag))
        # add preview attributes
        options.merge!(element_preview_code_attributes(element))

        # add tags
        if (tags_formatter = options.delete(:tags_formatter))
          options.merge!(element_tags_attributes(element, formatter: tags_formatter))
        end

        output = content_tag(tag, output, options)
      end

      # that's it!
      output
    end
  end
end
