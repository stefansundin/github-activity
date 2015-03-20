require "mail"

ENV["SENDGRID_SMTP_SERVER"] ||= "smtp.sendgrid.net"
ENV["MANDRILL_SMTP_SERVER"] ||= "smtp.mandrillapp.com"

ENV["SMTP_HOST"] ||= ENV["MANDRILL_SMTP_SERVER"] || ENV["SENDGRID_SMTP_SERVER"] || ENV["MAILGUN_SMTP_SERVER"] || ENV["POSTMARK_SMTP_SERVER"]
ENV["SMTP_PORT"] ||= ENV["MAILGUN_SMTP_PORT"] || "587"
ENV["SMTP_USERNAME"] ||= ENV["MANDRILL_USERNAME"] || ENV["SENDGRID_USERNAME"] || ENV["MAILGUN_SMTP_LOGIN"] || ENV["POSTMARK_API_KEY"]
ENV["SMTP_PASSWORD"] ||= ENV["MANDRILL_APIKEY"] || ENV["SENDGRID_PASSWORD"] || ENV["MAILGUN_SMTP_PASSWORD"] || ENV["POSTMARK_API_KEY"]

# If you use Postmark, you need to configure this SMTP_FROM manually
ENV["MAIL_FROM"] ||= ENV["MANDRILL_USERNAME"] || ENV["SENDGRID_USERNAME"] || ENV["MAILGUN_SMTP_LOGIN"]


Mail.defaults do
  delivery_method :smtp,
    address:              ENV["SMTP_HOST"],
    port:                 ENV["SMTP_PORT"],
    user_name:            ENV["SMTP_USERNAME"],
    password:             ENV["SMTP_PASSWORD"],
    authentication:       "plain",
    enable_starttls_auto: true
end
