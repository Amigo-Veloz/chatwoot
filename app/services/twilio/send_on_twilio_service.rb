require 'net/http'
require 'net/https' if RUBY_VERSION < '1.9'
require 'uri'

class Twilio::SendOnTwilioService < Base::SendOnChannelService
  private

  def channel_class
    Channel::TwilioSms
  end

  def perform_reply
    begin
      twilio_message = client.messages.create(**message_params)
    rescue Twilio::REST::TwilioError => e
      Sentry.capture_exception(e)
    end
    message.update!(source_id: twilio_message.sid) if twilio_message
  end

  def message_params
    puts 'New Message'
    
    params = {
      body: message.content,
      from: channel.phone_number,
      to: contact_inbox.source_id
    }
    
    hasAttachments = false
    hasAttachments = true if message.attachments.present?
    
    if hasAttachments
      puts 'message attachments present'

      u = URI.parse(attachments)

      h = Net::HTTP.new u.host, u.port
      h.use_ssl = u.scheme == 'https'

      head = h.start do |ua|
        ua.head u.path
      
      puts head['location']
  
      params[:media_url] = head['location'] if message.attachments.present?
      puts 'Message Attachments' if message.attachments.present?
      puts attachments if message.attachments.present?
      puts ['https://images.unsplash.com/photo-1545093149-618ce3bcf49d?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=668&q=80'] if message.attachments.present?

    puts params
    params
  end

  def attachments
    message.attachments.map(&:file_url)
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end

  def outgoing_message?
    message.outgoing? || message.template?
  end

  def client
    ::Twilio::REST::Client.new(channel.account_sid, channel.auth_token)
  end
end
