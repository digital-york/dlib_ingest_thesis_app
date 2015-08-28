module ApplicationHelper

  def full_title(page_title = '')
    base_title = "York Digital Library Thesis Submission"
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end



end
