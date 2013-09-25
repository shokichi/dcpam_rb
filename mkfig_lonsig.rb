#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# standerd figure
# No.4 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
require 'optparse'
include MKfig
include NumRu

# option
opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-n VAR","--name=VAR") {|name| VarName = name}
opt.on("-o OPT","--figopt=OPT") {|hash| Figopt = hash}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}
opt.parse!(ARGV)

varname = VarName if defined?(VarName)
list = Utiles_spe::Explist.new(ARGV[0])
IWS = 1 if !defined?(IWS) or IWS.nil?


# DCL set
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

if !varname.nil? then
  Figopt ||= {}
  lonsig("varname",list,Figopt)
else
  lonsig("Temp",list,"min"=>120,"max"=>320,"nlev"=>20)
  lonsig("DQVapDtCond",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>20)
  lonsig("DQVapDtCumulus",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>20)  
  lonsig("DQVapDtLsc",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>40)
  lonsig("RH",list,"min"=>0,"max"=>100)
  lonsig("H2OLiq",list,"min"=>0,"max"=>1e-4)
  lonsig("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
  lonsig("V",list,"min"=>-10,"max"=>10)      
end

DCL.grcls
rename_img_file(list,__FILE__)
