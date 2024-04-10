module Fgdc2Aardvark
# Mapping from FGDC to Aardvark following:
#   https://opengeometadata.org/aardvark-fgdc-iso-crosswalk/
# Borrowing from:
# https://github.com/OpenGeoMetadata/GeoCombine/blob/draft_fgdc2Aardvark/lib/xslt/fgdc2Aardvark_draft_v1.xsl

  # input args:
  #   fgdc_url - publicly accessible URL to FGDC XML
  #   doc  -  nokogiri::XML::Document representing the FGDC XML
  def fgdc2aardvark(fgdc_url, doc)
    layer = {}

    # # Figure this out first, some of the other metadata
    # # is based on this value
    # @dct_rights_sm = doc2dct_rights_sm(doc)

    # Add each element in turn, following the order from the example at:
    #   https://opengeometadata.org/JSON-format/#example
    
    layer[:dct_title_s] = doc2dct_title_s(doc)
    layer[:dct_alternative_sm] = doc2dct_alternative_sm(doc)
    layer[:dct_description_sm] = doc2dct_description_sm(doc)
    layer[:dct_language_sm] = doc2dct_language_sm(doc)
    layer[:dct_creator_sm] = doc2dct_creator_sm(doc)
    layer[:dct_publisher_sm] = doc2dct_publisher_sm(doc)
    layer[:schema_provider_s] = doc2schema_provider_s(doc)
    layer[:gbl_resourceClass_sm] = doc2gbl_resourceClass_sm(doc)
    layer[:gbl_resourceType_sm] = doc2gbl_resourceType_sm(doc)
    layer[:dcat_theme_sm] = doc2dcat_theme_sm(doc)
    layer[:dcat_keyword_sm] = doc2dcat_keyword_sm(doc)
    layer[:dct_temporal_sm] = doc2dct_temporal_sm(doc)
    layer[:dct_issued_s] = doc2dct_issued_s(doc)
    layer[:gbl_indexYear_im] = doc2gbl_indexYear_im(doc)
    layer[:gbl_dateRange_drsim] = doc2gbl_dateRange_drsim(doc)
    layer[:dct_spatial_sm] = doc2dct_spatial_sm(doc)
    layer[:locn_geometry] = doc2locn_geometry(doc)
    layer[:dcat_bbox] = doc2dcat_bbox(doc)
    layer[:dcat_centroid] = doc2dcat_centroid(doc)
    layer[:pcdm_memberOf_sm] = doc2pcdm_memberOf_sm(doc)
    layer[:dct_isPartOf_sm] = doc2dct_isPartOf_sm(doc)
    layer[:dct_rights_sm] = doc2dct_rights_sm(doc)
    layer[:dct_license_sm] = doc2dct_license_sm(doc)
    layer[:dct_accessRights_s] = doc2dct_accessRights_s(doc)
    layer[:dct_format_s] = doc2dct_format_s(doc)
    layer[:dct_references_s] = doc2dct_references_s(doc)
    layer[:id] = doc2id(doc)
    layer[:dct_identifier_sm] = doc2dct_identifier_sm(doc)
    layer[:gbl_mdModified_dt] = doc2gbl_mdModified_dt(doc)
    layer[:gbl_mdVersion_s] = doc2gbl_mdVersion_s(doc)
    
    return JSON.pretty_generate(layer)

  end


  def doc2dct_title_s(doc)
    return doc.xpath("//idinfo/citation/citeinfo/title").text
  end

  def doc2dct_alternative_sm(doc)
  end

  def doc2dct_description_sm(doc)
    return doc.xpath("//idinfo/descript/abstract").text
  end

  def doc2dct_language_sm(doc)
    langdata = doc.xpath("//idinfo/descript/langdata").text
    return "English" if langdata.match /en/i

    # undetermined - default to English
    return "English"
  end

  def doc2dct_creator_sm(doc)
    # If not found, return empty array
    doc.xpath("//idinfo/citation/citeinfo/origin").map { |node|
      node.text.strip
    } || []
  end

  def doc2dct_publisher_sm(doc)
    # doc.xpath("//idinfo/citation/citeinfo/pubinfo/publish").text
    # doc.xpath("//idinfo/citation/citeinfo/pubinfo/publish").map(&:text.strip)
    doc.xpath("//idinfo/citation/citeinfo/pubinfo/publish").map { |node|
      node.text.strip
    }
  end

  def doc2schema_provider_s(doc)
    @provenance
  end

  def doc2gbl_resourceClass_sm(doc)
  end

  def doc2gbl_resourceType_sm(doc)
  end

  def doc2dcat_theme_sm(doc)
  end

  def doc2dcat_keyword_sm(doc)
  end

  def doc2dct_temporal_sm(doc)
  end

  def doc2dct_issued_s(doc)
    pubdate = doc.xpath("//idinfo/citation/citeinfo/pubdate").text
    dct_issued_s = '';
    return dct_issued_s unless pubdate.match /^A\d+^Z/

    dct_issued_s = dct_issued_s + pubdate[0..3] if pubdate.length >= 4
    dct_issued_s = dct_issued_s + "-" + pubdate[4..5] if pubdate.length >= 6
    dct_issued_s = dct_issued_s + "-" + pubdate[6..7] if pubdate.length == 8
    return dct_issued_s
  end

  def doc2gbl_indexYear_im(doc)
    # check each of four locations, find the first 4-digit sequence.
    if d = doc.at_xpath("//idinfo/timeperd/timeinfo/sngdate/caldate")
      d.text.scan(/\d\d\d\d/) { |year| return year }
    end
    if d = doc.at_xpath("//idinfo/timeperd/timeinfo/mdattim/sngdate/caldate")
      d.text.scan(/\d\d\d\d/) { |year| return year }
    end
    if d = doc.at_xpath("//idinfo/timeperd/timeinfo/rngdates/begdate")
      d.text.scan(/\d\d\d\d/) { |year| return year }
    end
    if d = doc.at_xpath("//idinfo/keywords/temporal/tempkey")
      d.text.scan(/\d\d\d\d/) { |year| return year }
    end

    # Couldn't find any date?
    return nil
  end

  def doc2gbl_dateRange_drsim(doc)
    if rngdates = doc.at_xpath("//idinfo/timeperd/timeinfo/rngdates")
      rngdates.xpath("begdate").text[0..3] + "-" + rngdates.xpath("enddate").text[0..3]
    end
  end

  def doc2dct_spatial_sm(doc)
    doc.xpath("//idinfo/keywords/place/placekey").map { |node|
      node.text.strip
    }
  end

  def doc2locn_geometry(doc)
    return "ENVELOPE(#{@westbc}, #{@eastbc}, #{@northbc}, #{@southbc})"
  end

  def doc2dcat_bbox(doc)
    return "ENVELOPE(#{@westbc}, #{@eastbc}, #{@northbc}, #{@southbc})"
  end

  def doc2dcat_centroid(doc)
  end

  def doc2pcdm_memberOf_sm(doc)
  end

  def doc2dct_isPartOf_sm(doc)
  end

  def doc2dct_rights_sm(doc)
    # Access Constraints
    accconst = doc.xpath("//idinfo/accconst").text
    return "Public" if accconst.match /Unrestricted/i
    return "Public" if accconst.match /No restriction/i
    return "Public" if accconst.match /None/i
    return "Restricted" if accconst.match /Columbia/i
    return "Restricted" if accconst.match /Restricted/i

    # Use Constraints
    useconst = doc.xpath("//idinfo/useconst").text
    return "Public" if accconst.match /Unrestricted/i
    return "Public" if accconst.match /No restriction/i
    return "Public" if accconst.match /None/i
    return "Restricted" if accconst.match /Columbia/i
    return "Restricted" if accconst.match /Restricted/i

    # Default
    return "Restricted"
  end

  def doc2dct_license_sm(doc)
  end

  def doc2dct_accessRights_s(doc)
    return doc2dct_rights_sm(doc)
  end

  def doc2dct_format_s(doc)
    sdtstype = doc.xpath('//metadata/spdoinfo/ptvctinf/sdtsterm/sdtstype').text
    return 'Shapefile' if sdtstype.match /G-polygon/i
    return 'Shapefile' if sdtstype.match /Point/i
    return 'Shapefile' if sdtstype.match /String/i

    direct = doc.xpath('//metadata/spdoinfo/direct').text
    return 'GeoTIFF' if direct.match /Raster/i
    return 'Shapefile' if direct.match /Point/i
    return 'Shapefile' if direct.match /Vector/i

    geoform = doc.xpath("//metadata/idinfo/citation/citeinfo/geoform").text.strip
    return "GeoTIFF" if geoform.match /raster digital data/i
    return "Shapefile" if geoform.match /vector digital data/i

    formname = doc.xpath("//metadata/distinfo/stdorder/digform/digtinfo/formname").text.strip
    return "GeoTIFF" if formname.match /TIFF/i
    return "image/jpeg" if formname.match /JPEG2000/i
    return "Shapefile" if formname.match /Shape/i

    # OK, just return whatever crazy string is in the geoform/formname
    return geoform if geoform.length > 0
    return formname if formname.length > 0

    # or, if those are both empty, undetermined.
    return "UNDETERMINED"
  end

  def doc2dct_references_s(doc)
  end

  def doc2id(doc)
  end

  def doc2dct_identifier_sm(doc)
    identifier = "#{@provenance}.#{@key}"
    # We'd begun with a more complex identifier locally.
    identifier = "urn:columbia.edu:#{identifier}" if @provenance == 'Columbia'
    return identifier
  end

  def doc2gbl_mdModified_dt(doc)
    if d = doc.at_xpath("//metainfo/metd")
      year, month, day = d.text[0..3], d.text[4..5], d.text[6..7]
      "#{year}-#{month}-#{day}T00:00:00Z"
    end
  end

  def doc2gbl_mdVersion_s(doc)
    "Aardvark"
  end


end




