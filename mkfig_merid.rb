#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# make standerd figure 
# 子午面断面
#

require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
include MKfig
include NumRu

config = {
  'Temp'   =>{"min"=>120,"max"=>320,"interval"=>10},
  'U'      =>{"min"=>-80,"max"=>80,"interval"=>5},
  'V'      =>{"min"=>-8,"max"=>8},
  'RH'     =>{"min"=>0,"max"=>100},
  'SigDot' =>{"min"=>-1.5e-6,"max"=>1.5e-6},
  'QVap'   =>{"min"=>0,"max"=>0.015},
  'H2OLiq' =>{"min"=>0,"max"=>5e-5},
  'Strm'   =>{"min"=>-50,"max"=>50,"nlev"=>20}
}

#################################################
# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set

list = Utiles_spe::Explist.new(ARGV[0])
IWS = get_iws

# DCL set
set_dcl(14)
  
FigType = "merid"
if !Opt.charge[:name].nil? then
  make_figure(Opt.charge[:name],list,set_figopt)
else
  config.keys.each{ |name| make_figure(name,list,config[name])}
end

DCL.grcls
rename_img_file(list,__FILE__)
