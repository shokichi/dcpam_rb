#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# standerd figure
# 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
require 'optparse'
include MKfig
include NumRu


config = {
  "OSRA"        =>{"min"=>-1200,"max"=>0},
  "OLRA"        =>{"min"=>0,"max"=>300},
  "EvapA"       =>{"max"=>1000},
  "SensA"       =>{"max"=>200},
  "SSRA"        =>{"min"=>-1000,"max"=>0},
  "SLRA"        =>{"min"=>0,"max"=>200},
  "Rain"        =>{"min"=>0,"max"=>1000},
  "RainCumulus" =>{"min"=>0,"max"=>1000},
  "RainLsc"     =>{"min"=>0,"max"=>1000},
  "SurfTemp"    =>{"min"=>220,"max"=>360},
  "Temp"        =>{"min"=>220,"max"=>320},
  "Ps"          =>{"min"=>98000,"max"=>102000},
  "RH"          =>{"min"=>0,"max"=>100},
  "H2OLiqIntP"  =>{"min"=>0,"max"=>0.5},
  "Albedo"      =>{"min"=>0,"max"=>1},
 "PrcWtr"       =>{"min"=>0,"max"=>100},      
  "U"           =>{"min"=>-20,"max"=>20}
}
###################################################

#
$Opt = OptCharge::OptCharge.new(ARGV)
$Opt.set
list = Utiles::Explist.new(ARGV[0])
IWS = get_iws

# DCL set
set_dcl

if !$Opt.charge[:name].nil? then
  make_figure($Opt.charge[:name],list,set_figopt)
else
  config.keys.each{ |name| make_figure(name,list,{:figtype=>"lon"}.merge(config[name]))}
end  
DCL.grcls
rename_img_file(list,__FILE__)
