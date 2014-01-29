#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# standerd figure
# No.4 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
include MKfig
include NumRu

# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set

list = Utiles_spe::Explist.new(ARGV[0])
IWS = get_iws

# DCL set
set_dcl(14)

FigType = "lonsig"
if !Opt.charge[:name].nil? then
  make_figure(Opt.charge[:name],list,set_figopt)
else
  make_figure("Temp",list,"min"=>120,"max"=>320,"nlev"=>20)
  make_figure("DQVapDtCond",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>20)
  make_figure("DQVapDtCumulus",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>20)  
  make_figure("DQVapDtLsc",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>40)
  make_figure("RH",list,"min"=>0,"max"=>100)
  make_figure("QVap",list,"min"=>0,"max"=>2e-2,"nlev"=>20)
  make_figure("H2OLiq",list,"min"=>0,"max"=>1e-4)
#  make_figure("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
#  make_figure("V",list,"min"=>-10,"max"=>10)      
  make_figure("SigDot",list,"min"=>-2e-6,"max"=>2e-6)
end

DCL.grcls
rename_img_file(list,__FILE__)
