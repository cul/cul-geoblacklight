module Fgdc2Geobl

  # Use the file-name to create reference to html version of FGDC
  # def fgdc2geobl(fgdc_file, fgdc_xml)
  # input args:
  #   doc  -  nokogiri::XML::Document representing the FGDC XML
  def fgdc2geobl(doc)
    # doc  = Nokogiri::XML(fgdc_xml) do |config|
    #   config.strict.nonet
    # end
    # 
    # # Set some instance variables,
    # # used in multiple fields below
    # set_variables(doc)

    layer = {}

    # Figure this out first, some of the other metadata
    # is based on this value
    @dc_rights = doc2dc_rights(doc)

    # Add each element in turn...
    layer[:uuid] = doc2uuid(doc)
    layer[:dc_identifier_s] = doc2dc_identifier(doc)
    layer[:dc_title_s] = doc2dc_title(doc)
    layer[:dc_description_s] = doc2dc_description(doc)
    # layer[:dc_rights_s] = doc2dc_rights(doc)
    layer[:dc_rights_s] = @dc_rights
    layer[:dct_provenance_s] = doc2dct_provenance(doc)
    # layer[:dct_references_s] = doc2dct_references(fgdc_file, doc)
    layer[:dct_references_s] = doc2dct_references(doc)
    layer[:georss_box_s] = doc2georss_box(doc)
    layer[:layer_id_s] = doc2layer_id(doc)
    layer[:layer_geom_type_s] = doc2layer_geom_type(doc)
    layer[:layer_modified_dt] = doc2layer_modified(doc)
    layer[:layer_slug_s] = doc2layer_slug(doc)
    layer[:solr_geom] = doc2solr_geom(doc)
    layer[:solr_year_i] = doc2solr_year(doc)
    layer[:dc_creator_sm] = doc2dc_creator(doc)
    layer[:dc_format_s] = doc2dc_format(doc)
    layer[:dc_language_s] = doc2dc_language(doc)
    layer[:dc_publisher_s] = doc2dc_publisher(doc)
    layer[:dc_subject_sm] = doc2dc_subject(doc)
    layer[:dc_type_s] = doc2dc_type(doc)
    layer[:dct_spatial_sm] = doc2dct_spatial(doc)
    layer[:dct_temporal_sm] = doc2dct_temporal(doc)
    layer[:dct_issued_s] = doc2dct_issued(doc)
    layer[:dct_isPartOf_sm] = doc2dct_isPartOf(doc)
    # omit?
    # layer[:georss_point_s] = doc2georss_point(doc)
    layer[:georss_polygon_s] = doc2georss_polygon(doc)

    return JSON.pretty_generate(layer)

  end


  def doc2uuid(doc)
    return "urn:columbia.edu:Columbia.#{@resdesc}"
  end

  def doc2dc_identifier(doc)
    # We're using the same value for uuid and dc_identifier
    return doc2uuid(doc)
  end

  def doc2dc_title(doc)
    return doc.xpath("//idinfo/citation/citeinfo/title").text
  end

  def doc2dc_description(doc)
    return doc.xpath("//idinfo/descript/abstract").text
  end

  def doc2dc_rights(doc)
    # TODO - implement CAS auth, so we can work more correctly with Restricted material
    # return "Public"

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

  def doc2dct_provenance(doc)
    return "Columbia"
  end

  # Documented here:
  #   https://github.com/geoblacklight/geoblacklight-schema
  #       /blob/master/docs/dct_references_schema.markdown
  # def doc2dct_references(fgdc_file, doc)
  def doc2dct_references(doc)

    # basename = File.basename(fgdc_file, '.xml')

    dct_references = {}
    ###   12 possible keys.  
    ###   Which ones are we able to provide?

    # Only Public content has been loaded into GeoServer.
    # Restricted content is only available via Direct Download.
    if @dc_rights == 'Public'
      # Web Mapping Service (WMS) 
      dct_references['http://www.opengis.net/def/serviceType/ogc/wms'] =
          APP_CONFIG['geoserver_url'] + '/wms/sde'
      # Web Feature Service (WFS)
      dct_references['http://www.opengis.net/def/serviceType/ogc/wfs'] =
          APP_CONFIG['geoserver_url'] + '/sde/ows'
    end

    # International Image Interoperability Framework (IIIF) Image API
    # Direct download file
    if onlink = doc.at_xpath("//idinfo/citation/citeinfo/onlink")
      if onlink.text.match /.columbia.edu/
        dct_references['http://schema.org/downloadUrl'] = onlink.text
      end
    end
    # Full layer description
    # Metadata in HTML
    dct_references['http://www.w3.org/1999/xhtml'] =
        APP_CONFIG['display_urls']['html'] + "/#{@resdesc}.html"
    # Metadata in ISO 19139
    dct_references['http://www.isotc211.org/schemas/2005/gmd/'] =
        APP_CONFIG['display_urls']['iso19139'] + "/#{@resdesc}.xml"
    # Metadata in MODS
    # ArcGIS FeatureLayer
    # ArcGIS TiledMapLayer
    # ArcGIS DynamicMapLayer
    # ArcGIS ImageMapLayer

    return dct_references.compact.to_json.to_s
  end

  def doc2georss_box(doc)
    return "#{@southbc} #{@westbc} #{@northbc} #{@eastbc}"
  end

  def doc2layer_id(doc)
    # return "Columbia:Columbia.#{@resdesc}"
    return "sde:columbia.#{@resdesc}".html_safe
  end

  # Possibly also consider:
  #   idinfo/keywords/theme/themekey
  #   spdoinfo/ptvctinf/esriterm/efeageom
  # Suggested vocabulary:
  #     "Point", "Line", "Polygon", "Raster", "Scanned Map", "Mixed"
  def doc2layer_geom_type(doc)
    sdtstype = doc.xpath("//metadata/spdoinfo/ptvctinf/sdtsterm/sdtstype").text
    return "Polygon" if sdtstype.match /G-polygon/i
    return "Point" if sdtstype.match /Point/i
    return "Line" if sdtstype.match /String/i

    direct = doc.xpath("//metadata/spdoinfo/direct").text
    return "Raster" if direct.match /Raster/i
    return "Point" if direct.match /Point/i

    indspref = doc.xpath("//metadata/spdoinfo/indspref").text
    return "Table" if indspref.match /Table/i

    # undetermined
    return "UNDETERMINED"
  end

  # 20100603 --> 2010-06-03T00:00:00Z
  def doc2layer_modified(doc)
    if d = doc.at_xpath("//metainfo/metd")
      year, month, day = d.text[0..3], d.text[4..5], d.text[6..7]
      "#{year}-#{month}-#{day}T00:00:00Z"
    end
  end

  def doc2layer_slug(doc)
    # a tidier version of the layer ID
    return doc2layer_id(doc).parameterize
  end

  # 2_transform.rb says:
  # :solr_geom  => "ENVELOPE(#{w}, #{e}, #{n}, #{s})",
  # Solr docs say:   "minX, maxX, maxY, minY order"
  def doc2solr_geom(doc)
    return "ENVELOPE(#{@westbc}, #{@eastbc}, #{@northbc}, #{@southbc})"
  end

  def doc2solr_year(doc)
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
    # elsif d = doc.at_xpath("//idinfo/timeperd/timeinfo/mdattim/sngdate/caldate")
    #   return d.text[0..3]
    # elsif d = doc.at_xpath("//idinfo/timeperd/timeinfo/rngdates/begdate")
    #   return d.text[0..3]
    # elsif d = doc.at_xpath("//idinfo/keywords/temporal/tempkey")
    #   return d.text[0..3]
    # end

    # Couldn't find any date?
    return "UNDETERMINED"
  end

  def doc2dc_creator(doc)
    # doc.xpath("//idinfo/citation/citeinfo/origin").map(&:text.strip)
    doc.xpath("//idinfo/citation/citeinfo/origin").map { |node|
      node.text.strip
    }
  end

  # Suggested vocabulary: Shapefile, GeoTIFF, ArcGRID
  def doc2dc_format(doc)

    # blacklight-schema's 2_transform.rb determines Format based on Layer Geometry
    layer_geom_type = doc2layer_geom_type(doc)
    return 'GeoTiff' if layer_geom_type.match /Raster/i
    return 'Shapefile' if layer_geom_type.match /Point|Line|Polygon/i
    return 'Paper' if layer_geom_type.match /Paper/i

    geoform = doc.xpath("//metadata/idinfo/citation/citeinfo/geoform").text.strip
    return "GeoTiff" if geoform.match /raster digital data/i
    return "Shapefile" if geoform.match /vector digital data/i

    formname = doc.xpath("//metadata/distinfo/stdorder/digform/digtinfo/formname").text.strip
    return "GeoTiff" if formname.match /TIFF/i
    return "Shapefile" if formname.match /Shape/i

    # OK, just return whatever crazy string is in the geoform/formname
    return geoform if geoform.length > 0
    return formname if formname.length > 0

    # or, if those are both empty, undetermined.
    return "UNDETERMINED"
  end

  def doc2dc_language(doc)
    langdata = doc.xpath("//idinfo/descript/langdata").text
    return "English" if langdata.match /en/i

    # undetermined
    return ""
  end

  def doc2dc_publisher(doc)
    # doc.xpath("//idinfo/citation/citeinfo/pubinfo/publish").text
    # doc.xpath("//idinfo/citation/citeinfo/pubinfo/publish").map(&:text.strip)
    doc.xpath("//idinfo/citation/citeinfo/pubinfo/publish").map { |node|
      node.text.strip
    }
  end

  def doc2dc_subject(doc)
    # doc.xpath("//idinfo/keywords/theme/themekey").map { |node|
    #   node.text.strip
    # }
    if iso_theme = doc.at('theme:has(themekt[text()="ISO 19115 Topic Categories"])')
      iso_theme.xpath(".//themekey").map { |node|
        node.text.strip
      }
    end
  end

  def doc2dc_type(doc)
    # Constant
    return "Dataset"
  end

  def doc2dct_spatial(doc)
    doc.xpath("//idinfo/keywords/place/placekey").map { |node|
      node.text.strip
    }
  end

  def doc2dct_temporal(doc)
    dates = []
    caldate_year = ''

    if d = doc.at_xpath("//idinfo/timeperd/timeinfo/sngdate/caldate")
      d.text.scan(/\d\d\d\d/) { |year|
        caldate_year = year
        dates << year
      }
      # caldate = d.text[0..3]
      # dates << caldate
    end

    if d = doc.at_xpath("//idinfo/timeperd/timeinfo/mdattim/sngdate")
      d.text.scan(/\d\d\d\d/) { |year| dates << year }
      # dates << d.text[0..3]
    end

    if rngdates = doc.at_xpath("//idinfo/timeperd/timeinfo/rngdates")
      rngdates.xpath("begdate").text[0..3] + "-" + rngdates.xpath("enddate").text[0..3]
    end

    if d = doc.at_xpath("//idinfo/keywords/temporal/tempkey")
      d.text.scan(/\d\d\d\d/) { |year|
        #  Add it... unless it's redundant with caldate_year, above
        next if year == caldate_year
        dates << year
      }
      # tempkey = d.text[0..3]
      # # Add it... unless it's redundant with caldate, above
      # dates << tempkey unless tempkey == caldate
    end

    return dates.compact
  end

  def doc2dct_issued(doc)
    pubdate = doc.xpath("//idinfo/citation/citeinfo/pubdate").text
    dct_issued = '';
    return dct_issued unless pubdate.match /^A\d+^Z/

    dct_issued = dct_issued + pubdate[0..3] if pubdate.length >= 4
    dct_issued = dct_issued + "-" + pubdate[4..5] if pubdate.length >= 6
    dct_issued = dct_issued + "-" + pubdate[6..7] if pubdate.length == 8
    return dct_issued
  end

  def doc2dct_isPartOf(doc)
    isPartOf = []
    doc.xpath("//idinfo/citation/citeinfo/lworkcit/citeinfo").each { |citeinfo|
      # isPartOf << citeinfo.xpath("title").text.strip
      # isPartOf << citeinfo.xpath("sername").text.strip
      citeinfo.xpath("title").map { |node| isPartOf << node.text.strip }
      citeinfo.xpath("sername").map { |node| isPartOf << node.text.strip }
    }
    doc.xpath("//idinfo/citation/citeinfo/serinfo").each { |citeinfo|
      # isPartOf << citeinfo.xpath("title").text.strip
      # isPartOf << citeinfo.xpath("sername").text.strip
      citeinfo.xpath("title").map { |node| isPartOf << node.text.strip }
      citeinfo.xpath("sername").map { |node| isPartOf << node.text.strip }
    }
    return isPartOf.flatten.compact
  end

  # omit?
  # def doc2georss_point(doc)
  #   return "UNDETERMINED"
  # end

  # Any set of x,y points which define the bounding polygon
  def doc2georss_polygon(doc)
    return [@northbc, @westbc,
            @northbc, @eastbc,
            @southbc, @eastbc,
            @southbc, @westbc,
            @northbc, @westbc].join(' ')
  end

  #####################
  def set_variables(doc)
    # the unique key for this metadata record
    @resdesc = doc.xpath("//resdesc").text.strip

    # bounding coordinates
    @northbc = doc.xpath("//idinfo/spdom/bounding/northbc").text.to_f
    @southbc = doc.xpath("//idinfo/spdom/bounding/southbc").text.to_f
    @eastbc = doc.xpath("//idinfo/spdom/bounding/eastbc").text.to_f
    @westbc = doc.xpath("//idinfo/spdom/bounding/westbc").text.to_f
  end


end




