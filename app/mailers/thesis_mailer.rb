class ThesisMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.thesis_mailer.submitted.subject
  #
  def submitted(email)
    @greeting = "Your thesis has been submitted successfully."
    Rails .logger.debug '===> Sending email to ' + email + ' ... '
    mail to: email, subject: "Thesis submission confirmation."
    Rails .logger.debug 'done.'
  end
end
