require 'spec_helper'
require './models/user'

RSpec.describe User do
  describe '.count' do
    let(:sql) { 'select count(*) from ksazd.users' }

    it 'calls DB with proper sql' do
      expect(DB).to receive(:query_value).with(sql)
      User.count
    end
  end
end
