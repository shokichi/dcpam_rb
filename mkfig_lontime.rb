#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# standerd figure
# ホフメラーダイアグラム

# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
require 'optparse'
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

if !varname.nil? then
  figopt = set_figopt
  lontime(varname,list,figopt)
else
  lontime("Rain",list,"nlev"=>20)
end

DCL.grcls
rename_img_file(list,__FILE__)
