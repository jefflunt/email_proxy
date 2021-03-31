require 'net/http'
require 'uri'

class Email < ApplicationRecord
  INVALID_EMAIL_MSG = "email does not appear to be valid"

  # TODO: Proper email validation is quite difficult, but this should suffice as
  # a starting point. More details, see:
  # https://stackoverflow.com/questions/201323/how-to-validate-an-email-address-using-a-regular-expression
  validates :to,
            presence: true,
            format: {
              with: /\A.+@.+\..+\Z/,
              message: INVALID_EMAIL_MSG
            }

  validates :from,
            presence: true,
            format: {
              with: /\A.+@.+\..+\Z/,
              message: INVALID_EMAIL_MSG
            }

  validates :to_name,
            :from_name,
            :subject,
            :body,
            presence: :true

  enum status: [ :queued, :sent, :failed ]

  # NOTE: This method will throw an exception if the configured
  # EmailProxy#provider is invalid. This is intentional in order to generate an
  # outage alert in the case that this service is improperly configured.
  def attempt_delivery
    send(EmailProxy.provider)
  end

  # YAGNI: For now, since we only support two providers, the integration is
  # done here, rather than add another layer of abstraction or indirection. If
  # the busienss logic or number of providers starts to get more complex we
  # probably want to pull this out into its own module.
  def spendgrid
    begin
      response = Net::HTTP.post(
        URI('https://bw-interviews.herokuapp.com/spendgrid/send_email'),
        {
          "sender": "#{from_name} <#{from}>",
          "recipient": "#{to_name} <#{to}>",
          "subject": subject,
          "body": body
        }.to_json,
        {
          "Content-Type" => "application/json",
          "x-api-key" => "api_key_GeQoxAP64rGyXFyRjmD96D0g"
        }
      )

      sent!
    rescue => e
      record_exception(e)
    end
  end

  def snailgun
    begin
    rescue => e
      record_exception(e)
    end
  end

  def record_exception(e)
    self.failure_msg = e.full_message
    self.save
    failed!
  end
end
