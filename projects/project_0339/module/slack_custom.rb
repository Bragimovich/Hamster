# frozen_string_literal: true

module SlackCustom
  def send_slack_msg(text)
    text = "#{"@Zaid Akram Mughal\n"} #{text}."
    # Slack::Web::Client.new(token: Storage.new.slack)
        # .chat_postMessage(channel: '0339_north_carolina_business_licenses',
        #                   text: text,
        #                   link_names: true,
        #                   as_user: true)
  end
end
