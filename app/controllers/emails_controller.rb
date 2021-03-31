class EmailsController < ApplicationController
  def create
    email = Email.new(email_params)

    if email.save
      return render(
        json: { id: email.id },
        status: :created
      )
    else
      return render(
        json: { errors: email.errors.messages },
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
