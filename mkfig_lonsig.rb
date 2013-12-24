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
IWS = 2 if Opt.charge[:ps] || Opt.charge[:eps]
IWS = 4 if Opt.charge[:png]
IWS = 1 if !defined? IWS

# DCL set
clrmp = 14  # カラーマップ
DCL::swlset('lwnd',false) if IWS==4
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

if !Opt.charge[:varname].nil then
  lonsig(Opt.charge[:varname],list,set_figopt)
else
  lonsig("Temp",list,"min"=>120,"max"=>320,"nlev"=>20)
  lonsig("DQVapDtCond",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>20)
  lonsig("DQVapDtCumulus",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>20)  
  lonsig("DQVapDtLsc",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>40)
  lonsig("RH",list,"min"=>0,"max"=>100)
  lonsig("QVap",list,"min"=>0,"max"=>2e-2,"nlev"=>20)
  lonsig("H2OLiq",list,"min"=>0,"max"=>1e-4)
#  lonsig("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
#  lonsig("V",list,"min"=>-10,"max"=>10)      
  lonsig("SigDot",list,"min"=>-2e-6,"max"=>2e-6)
end

DCL.grcls
rename_img_file(list,__FILE__)
