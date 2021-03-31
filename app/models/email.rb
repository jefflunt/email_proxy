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
end
