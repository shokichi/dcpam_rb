#!/usr/bin/env ruby
#
#

wait = ARGV[1].to_f if ARGV.index("-d")
wait = 10 if wait==0 || wait==nil
loop{
  if !`ps -A | grep dcpam`.include?("dcpam")  then
    system("./run.sh")
    print "Start run.sh [#{Time.now}]"
    break
  end
  sleep wait*60
}
