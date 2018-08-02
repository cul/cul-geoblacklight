module Fgdc2Geobl

  # Use the file-name to create reference to html version of FGDC
  # def fgdc2geobl(fgdc_file, fgdc_xml)
  # input args:
  #   fgdc_file - original arbitrary XML filename, does NOT equal resdesc
  #   doc  -  nokogiri::XML::Document representing the FGDC XML
  def fgdc2geobl(fgdc_file, doc)
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

    # Add each element in turn, alpha order

    layer[:dc_creator_sm] = doc2dc_creator(doc)
    layer[:dc_description_s] = doc2dc_description(doc)
    layer[:dc_format_s] = doc2dc_format(doc)
    layer[:dc_identifier_s] = doc2dc_identifier(doc)
    layer[:dc_language_s] = doc2dc_language(doc)
    layer[:dc_publisher_s] = doc2dc_publisher(doc)
    layer[:dc_rights_s] = @dc_rights
    layer[:dc_subject_sm] = doc2dc_subject(doc)
    layer[:dc_title_s] = doc2dc_title(doc)
    layer[:dc_type_s] = doc2dc_type(doc)

    layer[:dct_isPartOf_sm] = doc2dct_isPartOf(doc)
    layer[:dct_issued_s] = doc2dct_issued(doc)
    layer[:dct_provenance_s] = doc2dct_provenance(doc)
    layer[:dct_references_s] = doc2dct_references(fgdc_file, doc)
    layer[:dct_source_sm] = []
    layer[:dct_spatial_sm] = doc2dct_spatial(doc)
    layer[:dct_temporal_sm] = doc2dct_temporal(doc)

    layer[:geoblacklight_version] = "1.0"

    layer[:layer_geom_type_s] = doc2layer_geom_type(doc)
    layer[:layer_id_s] = doc2layer_id(doc)
    layer[:layer_modified_dt] = doc2layer_modified(doc)
    layer[:layer_slug_s] = doc2layer_slug(doc)
    layer[:solr_geom] = doc2solr_geom(doc)
    layer[:solr_year_i] = doc2solr_year(doc)



    # layer[:georss_point_s] = doc2georss_point(doc)
    # layer[:georss_box_s] = doc2georss_box(doc)
    # layer[:georss_polygon_s] = doc2georss_polygon(doc)

    return JSON.pretty_generate(layer)

  end


  # def doc2uuid(doc)
  #   return "urn:columbia.edu:Columbia.#{@key}"
  # end

  def doc2dc_identifier(doc)
    identifier = "#{@provenance}.#{@key}"
    # We'd begun with a more complex identifier locally.
    identifier = "urn:columbia.edu:#{identifier}" if @provenance == 'Columbia'
    return identifier

    # # We're using the same value for uuid and dc_identifier
    # return doc2uuid(doc)
  end

  def doc2dc_title(doc)
    return doc.xpath("//idinfo/citation/citeinfo/title").text
  end

  def doc2dc_description(doc)
    return doc.xpath("//idinfo/descript/abstract").text
  end

  def doc2dc_rights(doc)
    # To get started, set everything to 'public'
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
    # return "Columbia"
    return @provenance
  end

  # Documented here:
  #   https://github.com/geoblacklight/geoblacklight-schema
  #       /blob/master/docs/dct_references_schema.markdown
  # docs moved to:
  # https://github.com/geoblacklight/geoblacklight/wiki/Schema
  def doc2dct_references(fgdc_file, doc)

    # basename = File.basename(fgdc_file, '.xml')

    dct_references = {}
    ###   12 possible keys.  
    ###   Which ones are we able to provide?

    # Only Public content has been loaded into GeoServer.
    # Restricted content is only available via Direct Download.
    if @dc_rights == 'Public'
      # AND - Raster data is NEVER loaded into GeoServer.
      layer_geom_type = doc2layer_geom_type(doc)
      unless layer_geom_type == 'Raster'
        # Web Mapping Service (WMS) 
        dct_references['http://www.opengis.net/def/serviceType/ogc/wms'] =
            # APP_CONFIG['geoserver_url'] + '/wms/sde'
            @geoserver_wms_url
        # Web Feature Service (WFS)
        dct_references['http://www.opengis.net/def/serviceType/ogc/wfs'] =
            # APP_CONFIG['geoserver_url'] + '/sde/ows'
            @geoserver_wfs_url
      end
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
    die "No APP_CONFIG['display_urls']['html']" unless APP_CONFIG['display_urls']['html']
    dct_references['http://www.w3.org/1999/xhtml'] =
        APP_CONFIG['display_urls']['html'] + "/#{@key}.html"
    # # Metadata in ISO 19139
    # dct_references['http://www.isotc211.org/schemas/2005/gmd/'] =
    #     APP_CONFIG['display_urls']['iso19139'] + "/#{@key}.xml"
    # Metadata in FGDC
    die "No APP_CONFIG['display_urls']['fgdc']" unless APP_CONFIG['display_urls']['fgdc']
    dct_references['http://www.opengis.net/cat/csw/csdgm'] =
        APP_CONFIG['display_urls']['fgdc'] + "/" + File.basename(fgdc_file)
    # Metadata in MODS
    # ArcGIS FeatureLayer
    # ArcGIS TiledMapLayer
    # ArcGIS DynamicMapLayer
    # ArcGIS ImageMapLayer

    return dct_references.compact.to_json.to_s
  end

  # def doc2georss_box(doc)
  #   return "#{@southbc} #{@westbc} #{@northbc} #{@eastbc}"
  # end

  # The layer_id needs to be the identifier of this layer in the
  # institution's GeoServer installation.
  # The mapping of @key to layer_id cannot be generalized,
  # so cases are hardcoded below.
  def doc2layer_id(doc)
    case @provenance
    when 'Columbia'
      "sde:columbia.#{@key}".html_safe
    when 'Harvard'
      @key.html_safe
    when 'Tufts'
      "sde:GISPORTAL.GISOWNER01.#{@key.upcase}"
    else
      raise "ERROR:  doc2layer_id() got unknown provenance @provenance"
    end
    
    # return "Columbia:Columbia.#{@key}"
    # return "sde:columbia.#{@key}".html_safe
    # return "sde:#{@provenance.downcase}.#{@key}".html_safe
  end

  # Possibly also consider:
  #   idinfo/keywords/theme/themekey
  #   spdoinfo/ptvctinf/esriterm/efeageom
  # Suggested vocabulary:
  #     "Point", "Line", "Polygon", "Raster", "Scanned Map", "Mixed"
  def doc2layer_geom_type(doc)
    sdtstype = doc.xpath('//metadata/spdoinfo/ptvctinf/sdtsterm/sdtstype').text
    return 'Polygon' if sdtstype.match /G-polygon/i
    return 'Point' if sdtstype.match /Point/i
    return 'Line' if sdtstype.match /String/i

    direct = doc.xpath('//metadata/spdoinfo/direct').text
    return 'Raster' if direct.match /Raster/i
    return 'Point' if direct.match /Point/i
    return 'Polygon' if direct.match /Vector/i

    indspref = doc.xpath('//metadata/spdoinfo/indspref').text
    return 'Table' if indspref.match /Table/i

    # undetermined
    return 'UNDETERMINED'
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
    return nil
  end

  def doc2dc_creator(doc)
    # If not found, return empty array
    doc.xpath("//idinfo/citation/citeinfo/origin").map { |node|
      node.text.strip
    } || []
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

    # undetermined - default to English
    return "English"
  end

  def doc2dc_publisher(doc)
    # doc.xpath("//idinfo/citation/citeinfo/pubinfo/publish").text
    # doc.xpath("//idinfo/citation/citeinfo/pubinfo/publish").map(&:text.strip)
    doc.xpath("//idinfo/citation/citeinfo/pubinfo/publish").map { |node|
      node.text.strip
    }
  end

  def doc2dc_subject(doc)
    # ALL subjects?
    doc.xpath("//idinfo/keywords/theme/themekey").map { |node|
      node.text.strip
    }

    # filter by vocabulary?
    # subjects = []
    # if iso_theme = doc.at('theme:has(themekt[text()="ISO 19115 Topic Categories"])')
    #   subjects << iso_theme.xpath(".//themekey").map { |node|
    #     node.text.strip.capitalize
    #   }
    # end
    # subjects
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

  # # Any set of x,y points which define the bounding polygon
  # def doc2georss_polygon(doc)
  #   return [@northbc, @westbc,
  #           @northbc, @eastbc,
  #           @southbc, @eastbc,
  #           @southbc, @westbc,
  #           @northbc, @westbc].join(' ')
  # end

  #####################
  def set_variables(repo, doc)
    # fetch repo-specific configuration variables
    fgdc_mapping_constants = APP_CONFIG['fgdc_mapping_constants']
    abort "Missing fgdc_mapping_constants from app_config!" unless fgdc_mapping_constants.present?
    repo_config = fgdc_mapping_constants[repo]
    abort "Missing fgdc mapping details for repo #{repo} in app_config!" unless repo_config.present?
    @provenance         =  repo_config['provenance']
    @geoserver_wms_url  =  repo_config['geoserver_wms_url']
    @geoserver_wfs_url  =  repo_config['geoserver_wfs_url']
    @key_xpath          =  repo_config['key_xpath']
  
    
    # the unique key for this metadata record
    key = doc.xpath(@key_xpath)
    key = key.text if key.class == Nokogiri::XML::NodeSet
    @key = key.to_s.strip

    # bounding coordinates
    @northbc = doc.xpath("//idinfo/spdom/bounding/northbc").text.to_f
    @southbc = doc.xpath("//idinfo/spdom/bounding/southbc").text.to_f
    @eastbc = doc.xpath("//idinfo/spdom/bounding/eastbc").text.to_f
    @westbc = doc.xpath("//idinfo/spdom/bounding/westbc").text.to_f
  end


end




