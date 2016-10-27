module ApplicationHelper

  # For Columbia, ALL documents are downloadable,
  # if they have an authenticated Direct Download link.
  def document_downloadable?
    # document_available? && @document.downloadable?
    # return true
    @document.direct_download.present?
  end

end
