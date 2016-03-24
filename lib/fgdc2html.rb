module Fgdc2Html

  def fgdc2html(fgdc_file, fgdc_xml)

    doc  = Nokogiri::XML(fgdc_xml) do |config|
      config.strict.nonet
    end

    return xsl_html.transform(doc).to_html

  end


  ##
  # Returns a Nokogiri::XSLT object containing the ISO19139 to HTML XSL
  # @return [Nokogiri:XSLT]
  def xsl_html
    Nokogiri::XSLT(File.open(File.join(File.dirname(__FILE__), '/xslt/fgdc2html.xsl')))
  end

end

