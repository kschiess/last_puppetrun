require 'spec_helper'

load 'last_puppetrun'

def fixture(name)
  File.join(
    File.dirname(__FILE__), 
    '../fixtures', 
    name)
end

describe PuppetRuns do
  attr_reader :instance
  before(:each) do
    @instance = PuppetRuns.new
  end
  
  describe "#controlled_hosts return value" do
    attr_reader :return_value
    before(:each) do
      flexmock(instance, :run => 
      "+ amaltheo.geo.uzh.ch (D6:1A:1B:37:C0:C9:63:14:19:CE:10:C5:B7:92:DA:2B)\n+ anthex.geo.uzh.ch (16:46:55:D2:FD:E7:FE:3D:41:CD:C3:AC:C4:E4:47:4F)\n+ arcsda.geo.uzh.ch (EF:41:9C:93:B3:E9:DE:44:56:56:F0:12:E5:63:F3:29)\n+ bbs.geo.uzh.ch (0A:C4:48:A6:80:41:CB:9B:35:BA:5A:54:24:75:91:32)\n+ beanstalker.geo.uzh.ch (A5:25:0D:53:D6:97:CF:E4:8E:A1:AF:8F:6B:F2:8A:42)\n+ belly.geo.uzh.ch (AD:A6:3A:10:EA:F1:9F:46:A6:88:F4:79:2D:59:C2:F5)\n"
      )
      
      @return_value = instance.controlled_hosts
    end
    
    it "should be a list" do
      return_value.should be_an_instance_of(Array)
    end
    it "should include 'anthex.geo.uzh.ch'" do
      return_value.should include('anthex.geo.uzh.ch')
    end
    it "should include 'belly.geo.uzh.ch'" do
      return_value.should include('belly.geo.uzh.ch')
    end
  end
  describe "#each_log_line yields" do
    attr_reader :yields
    before(:each) do
      flexmock(File, :readlines => File.readlines(fixture('syslog')))
      
      @yields = []
      instance.each_log_line do |stuff|
        @yields << stuff
      end
    end
    
    it "should yield each line of the log with a timestamp" do
      yields.should include([
        Time.parse('Jan 25 15:41:50'),
        'puppet puppetmasterd[884]: Compiled catalog for hyperion.example.com in 1.45 seconds'])
    end
  end
  describe "#each_successful_run yields" do
    attr_reader :runs, :spec_time
    before(:each) do
      @spec_time = Time.now
      
      flexmock(instance).
        should_receive(:each_log_line).
          and_yield([Time.now, 'puppet puppetmasterd[884]: Compiled catalog for hyperion.geo.uzh.ch in 1.45 seconds']).
          and_yield([Time.now, "puppet puppetd[15852]: (//Node[ubuntu]/Service[ssh]) Failed to call refresh on Service[ssh]: Could not stop Service[ssh]: Execution of '/etc/init.d/ssh stop' returned 1:  at /etc/puppet/manifests/templates/ubuntu.pp:48"])
      
      @runs = []
      instance.each_successful_run { |stuff| @runs << stuff }
    end
    
    it "should include hyperion" do
      runs.map { |(ts,host)| host }.should include('hyperion.geo.uzh.ch')
    end
  end
 
  describe "#parse_logfile" do    
    before(:each) do
      flexmock(File, :readlines => File.readlines(fixture('syslog')))
   
      instance.parse_logfile
    end
    
    it "should initialize last_run('mimas.geo.uzh.ch')" do
      instance.last['elara.example.com'].should_not be_nil
    end 
  end
end

describe PuppetRuns::LastRun do
  attr_reader :instance, :spec_time
  before(:each) do
    @spec_time = Time.now
    @instance = PuppetRuns::LastRun.new('test', spec_time - 10.minutes)
  end
  
  it "should have name 'test'" do
    instance.name.should == 'test'
  end
  it "should be 10 minutes ago" do
    instance.time_ago_in_minutes(spec_time).should == 10
  end 
end