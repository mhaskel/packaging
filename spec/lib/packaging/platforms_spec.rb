require 'spec_helper'

describe 'Pkg::Platforms' do
  describe '#platform_tags' do
    it 'should return an array of platform tags' do
      tags = Pkg::Platforms.platform_tags
      expect(tags).to be_instance_of(Array)
      expect(tags.count).to be > 0
    end

    it 'should include a basic platform' do
      tags = Pkg::Platforms.platform_tags
      expect(tags).to include('el-7-x86_64')
    end
  end

  describe '#parse_platform_tag' do
    it 'fails with a reasonable error on invalid platform' do
      expect { Pkg::Platforms.parse_platform_tag('abcd-15-ia64') }.to raise_error(/valid platform tag/)
    end
  end
end
