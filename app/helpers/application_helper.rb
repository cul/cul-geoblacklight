module ApplicationHelper

  # For Columbia, ALL documents are downloadable via
  # an authenticated Direct Download link.
  def document_downloadable?
    # document_available? && @document.downloadable?
    return true
  end

end
