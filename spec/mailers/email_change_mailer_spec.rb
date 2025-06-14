require "rails_helper"

RSpec.describe EmailChangeMailer, type: :mailer do
  describe "request_submitted" do
    let(:mail) { EmailChangeMailer.request_submitted }

    it "renders the headers" do
      expect(mail.subject).to eq("Request submitted")
      expect(mail.to).to eq([ "to@example.org" ])
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "approved_notification" do
    let(:mail) { EmailChangeMailer.approved_notification }

    it "renders the headers" do
      expect(mail.subject).to eq("Approved notification")
      expect(mail.to).to eq([ "to@example.org" ])
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "rejected_notification" do
    let(:mail) { EmailChangeMailer.rejected_notification }

    it "renders the headers" do
      expect(mail.subject).to eq("Rejected notification")
      expect(mail.to).to eq([ "to@example.org" ])
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end
end
