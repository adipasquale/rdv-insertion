describe Stats::GlobalStats::UpsertStatsJob do
  subject do
    described_class.new.perform
  end

  let!(:department1) { create(:department) }
  let!(:department2) { create(:department) }
  let!(:department3) { create(:department) }

  let!(:organisation1) { create(:organisation, department: department1) }
  let!(:organisation2) { create(:organisation, department: department2) }

  describe "#perform" do
    before do
      allow(Stats::GlobalStats::UpsertStatJob).to receive(:perform_later)
        .and_return(OpenStruct.new(success?: true))
    end

    it "calls the appropriate service" do
      expect(Stats::GlobalStats::UpsertStatJob).to receive(:perform_later).at_least(1).time
      subject
    end
  end
end
