module ApplicationHelper
  def event_date_badge(event)
    tag.div class: "date-badge" do
      tag.span(event.starts_at.strftime("%b"), class: "date-badge__month") +
        tag.span(event.starts_at.day, class: "date-badge__day")
    end
  end

  def event_time(event)
    event.starts_at.strftime("%A, %-d %B %Y · %H:%M")
  end
end
