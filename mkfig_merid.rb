# -*- coding: utf-8 -*-
3#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# make standerd figure 
# 子午面断面
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
set_dcl(14)
  
GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
GGraph.set_fig('window'=>[-90,90,nil,nil])

FigType = "merid"
if !Opt.charge[:varname].nil? then
  make_figure(Opt.charge[:varname],list,set_figopt)
else
  make_figure('Temp',list,"min"=>120,"max"=>320,"interval"=>10)
  make_figure('U',list,"min"=>-80,"max"=>80,"interval"=>5)
  make_figure('V',list,"min"=>-8,"max"=>8)
  make_figure('RH',list,"min"=>0,"max"=>100)
  make_figure('SigDot',list,"min"=>-1.5e-6,"max"=>1.5e-6)
  make_figure('QVap',list,"min"=>0,"max"=>0.015)
  make_figure('H2OLiq',list,"min"=>0,"max"=>5e-5)
  make_figure('Strm',list,"min"=>-50,"max"=>50,"nlev"=>20)
end

DCL.grcls
rename_img_file(list,__FILE__)
