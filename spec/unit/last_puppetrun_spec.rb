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
        "+ cruise.geo.uzh.ch\n+ dactyl.geo.uzh.ch\n+ deimos.geo.uzh.ch\n+ dsgz.geo.uzh.ch\n+ elara.geo.uzh.ch\n+ gd1.geo.uzh.ch\n+ gd2.geo.uzh.ch\n+ gironimo.geo.uzh.ch\n+ hyperion.geo.uzh.ch\n+ kale.geo.uzh.ch\n+ keskonrix.geo.uzh.ch\n+ ldap1.geo.uzh.ch\n+ ldap2.geo.uzh.ch\n+ leda.geo.uzh.ch\n+ ls0.geo.uzh.ch\n+ ls1.geo.uzh.ch\n+ ls2.geo.uzh.ch\n+ ls3.geo.uzh.ch\n+ ls4.geo.uzh.ch\n+ ls9.geo.uzh.ch\n+ mail.geo.uzh.ch\n+ mail2.geo.uzh.ch\n+ marbles.geo.uzh.ch\n+ metis.geo.uzh.ch\n+ mimas.geo.uzh.ch\n+ moon.geo.uzh.ch\n+ mq.geo.uzh.ch\n+ neso.geo.uzh.ch\n+ olaf.geo.uzh.ch\n+ orat.geo.uzh.ch\n+ phobos.geo.uzh.ch\n+ puppet.geo.uzh.ch\n+ rooms.geo.uzh.ch\n+ roya-ve.geo.uzh.ch\n+ shermy.geo.uzh.ch\n+ tethys.geo.uzh.ch\n+ thebe.geo.uzh.ch\n+ titan.geo.uzh.ch\n+ ubuntu-build-host.geo.uzh.ch\n+ vm01.geo.uzh.ch\n+ wildnispark.geo.uzh.ch\n"
      )
      
      @return_value = instance.controlled_hosts
    end
    
    it "should be a list" do
      return_value.should be_an_instance_of(Array)
    end
    it "should include 'mimas.geo.uzh.ch'" do
      return_value.should include('mimas.geo.uzh.ch')
    end
    it "should include 'puppet.geo.uzh.ch'" do
      return_value.should include('puppet.geo.uzh.ch')
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