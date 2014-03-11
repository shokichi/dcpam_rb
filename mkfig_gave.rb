#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Global average

require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
include MKfig
include NumRu

config = {
  "OSRA"=>{"min"=>0,"max"=>-320},
  "OLRA"=>{"min"=>0,"max"=>320},
  "EvapA"=>{"min"=>-20,"max"=>300},
  "SensA"=>{"min"=>-20,"max"=>300},
  "SSRA"=>{"min"=>20,"max"=>-300},
  "SLRA"=>{"min"=>-20,"max"=>300},
  "Temp"=>{"min"=>200,"max"=>300},
  "SurfTemp"=>{"min"=>200,"max"=>300},
  "Rain"=>{"min"=>0,"max"=>6000},
  "RainCumulus"=>{"min"=>0,"max"=>6000},
  "RainLsc"=>{"min"=>0,"max"=>6000},
  "Ps"=>{"min"=>90000,"max"=>110000},
  "PrcWtr"=>{"min"=>0,"max"=>50}
}

##########################################
# option
$Opt = OptCharge::OptCharge.new(ARGV)
$Opt.set
list = Explist.new(ARGV[0])
IWS = get_iws

# DCL set
set_dcl

if !$Opt.charge[:name].nil? then
  make_figure($Opt.charge[:name],list,set_figopt)
else
  config.keys.each{ |name|
    make_figure(name,list,{figtype:"time"}.merge(config[name]))
  }
end  

DCL.grcls
rename_img_file(list,__FILE__)


