#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# standerd figure
# No.4 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
include MKfig
include NumRu


config = {
  "OSRA"        =>{"min"=>-1200,"max"=>0,"nlev"=>20,"clr_min"=>99,"clr_max"=>56},
  "OLRA"        =>{"min"=>0,"max"=>300,"nlev"=>20,"clr_min"=>56,"clr_max"=>13},
  "EvapA"       =>{"max"=>1000,"clr_min"=>56,"clr_max"=>13},
  "SensA"       =>{"max"=>200,"nlev"=>20,"clr_min"=>56,"clr_max"=>13},
  "SSRA"        =>{"min"=>-1000,"max"=>0,"clr_min"=>99,"clr_max"=>56},
  "SLRA"        =>{"min"=>0,"max"=>200,"nlev"=>20,"clr_min"=>56,"clr_max"=>13},
  "Rain"        =>{"min"=>0,"max"=>1000,"nlev"=>20},
  "RainCumulus" =>{"min"=>0,"max"=>500},
  "RainLsc"     =>{"min"=>0,"max"=>500,"nlev"=>20},
  "SurfTemp"    =>{"min"=>220,"max"=>360},
  "Temp"        =>{"min"=>220,"max"=>320},
  "RH"          =>{"min"=>0,"max"=>100},
  "H2OLiqIntP"  =>{"min"=>0,"max"=>1,"nlev"=>20},
  "PrcWtr"      =>{"min"=>0,"max"=>100,"nlev"=>20},      
  "U"           =>{"min"=>-20,"max"=>20,"nlev"=>20},      
  "V"           =>{"min"=>-10,"max"=>10}
}

####################################################
# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set

list = Utiles_spe::Explist.new(ARGV[0])
IWS = get_iws
set_dcl(14)

FigType = "lonlat"
if !Opt.charge[:name].nil? then
  make_figure(Opt.charge[:name],list,set_figopt)
else
  config.keys.each{ |name| make_figure(name,list,config[name])}
end  
DCL.grcls
rename_img_file(list,__FILE__)
