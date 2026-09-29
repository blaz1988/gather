require "rails_helper"

RSpec.describe User do
  it "needs a name and a unique email address" do
    create(:user, email_address: "ana@gather.test")
    expect(build(:user, name: "")).not_to be_valid
    expect(build(:user, email_address: " ANA@gather.test ")).not_to be_valid
  end
end
