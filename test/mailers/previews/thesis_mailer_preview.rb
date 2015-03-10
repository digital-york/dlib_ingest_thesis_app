# Preview all emails at http://localhost:3000/rails/mailers/thesis_mailer
class ThesisMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/thesis_mailer/submitted
  def submitted
    ThesisMailer.submitted
  end

end
