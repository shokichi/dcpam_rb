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


#
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set
list = Utiles_spe::Explist.new(ARGV[0])
IWS = get_iws

# DCL set
set_dcl

FigType = "lon"
if !Opt.charge[:name].nil? then
  make_figure(Opt.charge[:name],list,set_figopt)
else
  make_figure("OSRA",list,"min"=>-1200,"max"=>0)
  make_figure("OLRA",list,"min"=>0,"max"=>300)
  make_figure("EvapA",list,"max"=>1000)
  make_figure("SensA",list,"max"=>200)
  make_figure("SSRA",list,"min"=>-1000,"max"=>0)
  make_figure("SLRA",list,"min"=>0,"max"=>200)
  make_figure("Rain",list,"min"=>0,"max"=>1000)
  make_figure("RainCumulus",list,"min"=>0,"max"=>1000)
  make_figure("RainLsc",list,"min"=>0,"max"=>1000)
  make_figure("SurfTemp",list,"min"=>220,"max"=>360)
  make_figure("Temp",list,"min"=>220,"max"=>320)
  make_figure("Ps",list,"min"=>98000,"max"=>102000)
  make_figure("RH",list,"min"=>0,"max"=>100)
  make_figure("H2OLiqIntP",list,"min"=>0,"max"=>0.5)
  make_figure("Albedo",list,"min"=>0,"max"=>1)
  make_figure("PrcWtr",list,"min"=>0,"max"=>100)      
  make_figure("U",list,"min"=>-20,"max"=>20)      
end  
DCL.grcls
rename_img_file(list,__FILE__)
