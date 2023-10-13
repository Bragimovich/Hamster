# frozen_string_literal: true

module SlackCustom
  def send_slack_msg(text, to_channel: false, to_nobody: false)
    raise "Message can't be to_channel and to_nobody at the same time" if to_channel && to_nobody

    text = "#{"@channel\n"} #{text}."        if to_channel && !to_nobody
    text = "#{text}"                         if !to_channel && to_nobody
    text = "#{"@anton.storchak\n"} #{text}." if !to_channel && !to_nobody

    Slack::Web::Client.new(token: Storage.new.slack)
        .chat_postMessage(channel: 'hle_pa_state_cc',
                          text: text,
                          link_names: true,
                          as_user: true)
  end
end
