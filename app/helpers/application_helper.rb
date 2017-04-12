module ApplicationHelper

  # For Columbia, ALL documents are downloadable,
  # if they have an authenticated Direct Download link.
  def document_downloadable?
    # document_available? && @document.downloadable?
    # return true
    @document.direct_download.present?
  end

  def application_uptime
    time_ago_in_words(BOOTED_AT)
  end

end
