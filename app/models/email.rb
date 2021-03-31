class Email < ApplicationRecord
  enum status: [ :queued, :sent, :failed ]
end
