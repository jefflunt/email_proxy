class EmailsController < ApplicationController
  def create
    email = Email.create(email_params(params))

    if email
      return render(
        json: { id: email.id },
        status: :created
      )
    else
      return render(
        json: { err: { msgs: email.errors.messages } },
        status: :unprocessable_entity
      )
    end
  end

  private
    def _email_params
      params
        .require(:email)
        .permit(:to, :to_name, :from, :from_name, :subject, :body)
    end
end
