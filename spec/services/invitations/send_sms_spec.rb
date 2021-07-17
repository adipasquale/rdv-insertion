describe Invitations::SendSms, type: :service do
  subject do
    described_class.call(
      invitation: invitation,
      phone_number: phone_number
    )
  end

  let!(:phone_number) { "+33728288282" }
  let!(:applicant) { create(:applicant, department: department) }
  let!(:department) do
    create(
      :department,
      rdv_solidarites_organisation_id: 27,
      number: "26",
      name: "Drôme",
      region: "Auvergne-Rhône-Alpes",
      phone_number: "0147200001"
    )
  end
  let!(:invitation) do
    create(:invitation, applicant: applicant, link: "https://www.rdv-solidarites.fr/lieux?invitation_token=123")
  end

  describe "#call" do
    let!(:content) do
      "Bonjour,\nVous êtes allocataire du RSA. Vous devez bénéficier d'un accompagnement obligatoire dans " \
      "le cadre de vos démarches d'insertion. Le département 26 (Drôme) " \
      "vous invite à prendre rendez-vous auprès d'un référent afin d'échanger sur votre situation.\n" \
      "Vous devez prendre rendez-vous en ligne à l'adresse suivante: "\
      "https://www.rdv-solidarites.fr/lieux?invitation_token=123\n" \
      "En cas d'absence, une sanction pourra être prononcée. Pour tout problème, contactez " \
      "le secrétariat au 0147200001."
    end

    before do
      allow(SendTransactionalSms).to receive(:call)
    end

    it("is a success") { is_a_success }

    it "calls the send transactional service" do
      expect(SendTransactionalSms).to receive(:call)
        .with(phone_number: phone_number, content: content)
      subject
    end
  end
end
