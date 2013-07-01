#!/usr/bin/ruby
#
#

wait = ARGV[1].to_f if ARGV.index("-d")
wait = 10 if wait==0 || wait==nil
loop{
  if !`ps -A | grep dcpam`.include?("dcpam")  then
    system("./run.sh")
    break
  end
  sleep wait*60
}
