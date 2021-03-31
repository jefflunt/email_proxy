class EmailsController < ApplicationController
  def create
    email = Email.new(email_params)

    if email.save
      email.attempt_delivery

      if email.sent?
        return render(
          json: { email_id: email.id, status: email.status },
          status: :created
        )
      else
        return render(
          json: { email_id: email.id, status: email.status, errors: email.failure_msg },
          status: :internal_server_error
        )
      end
    else
      return render(
        json: { status: email.status, errors: email.errors.messages },
        status: :unprocessable_entity
      )
    end
  end

  private
    def email_params
      params
        .require(:email)
        .permit(:to, :to_name, :from, :from_name, :subject, :body)
    end
end
