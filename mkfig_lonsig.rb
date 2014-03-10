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
  "Temp"=>          {"min"=>120,"max"=>320,"nlev"=>20},
  "DQVapDtCond"=>   {"min"=>-2e-7,"max"=>2e-7,"nlev"=>20},
  "DQVapDtCumulus"=>{"min"=>-2e-7,"max"=>2e-7,"nlev"=>20},  
  "DQVapDtLsc"=>    {"min"=>-2e-7,"max"=>2e-7,"nlev"=>40},
  "RH"=>            {"min"=>0,"max"=>100},
  "QVap"=>          {"min"=>0,"max"=>2e-2,"nlev"=>20},
  "H2OLiq"=>        {"min"=>0,"max"=>1e-4},
  "U"=>             {"min"=>-20,"max"=>20,"nlev"=>20},      
  "V"=>             {"min"=>-10,"max"=>10},      
  "SigDot"=>        {"min"=>-2e-6,"max"=>2e-6}
}

#######################################################
# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set

list = Utiles::Explist.new(ARGV[0])
IWS = get_iws

# DCL set
set_dcl(14)

FigType = "lonsig"
if !Opt.charge[:name].nil? then
  make_figure(Opt.charge[:name],list,set_figopt)
else
  config.keys.each{ |name| make_figure(name,list,{:figtype=>"lonsig"}.merge(config[name]))}
end

DCL.grcls
rename_img_file(list,__FILE__)
