module SoftwareDescriptionFetchers
  module Strategies
    #
    # Strategy to fetch description from Github
    #
    # @author [guillaumeh]
    #
    class Github
      def initialize(html_doc)
        @doc = html_doc
      end

      def fetch
        fetch_description
      end

      private

      def fetch_description
        xpath = '//div[contains(@class, "repository-meta-content")]/span/text()'
        @doc.xpath(xpath).first.try(:text).try(:squish)
      end
    end
  end
end
