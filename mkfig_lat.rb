#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 緯度分布の図を作成
# 

require "numru/ggraph"
require 'optparse'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/make_figure.rb")
include MKfig
include NumRu

# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set
list = Utiles_spe::Explist.new(ARGV[0])
IWS = get_iws2

# DCL set
set_dcl

GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
GGraph.set_fig('window'=>[-90,90,nil,nil])

FigType = "lat"
if !Opt.charge[:varname].nil? then
  make_figure(Opt.charge[:varname],list,set_figopt)
else
  make_figure("OSRA",list,"min"=>0,"max"=>-320)
  make_figure("OLRA",list,"min"=>0,"max"=>320)
  make_figure("EvapA",list,"min"=>-20,"max"=>300)
  make_figure("SensA",list,"min"=>-20,"max"=>300)
  make_figure("SSRA",list,"min"=>20,"max"=>-300)
  make_figure("SLRA",list,"min"=>-20,"max"=>300)
  make_figure("Temp",list,"min"=>200,"max"=>300)
  make_figure("SurfTemp",list,"min"=>200,"max"=>300)
  make_figure("Rain",list,"min"=>0,"max"=>6000)
  make_figure("RainCumulus",list,"min"=>0,"max"=>6000)
  make_figure("RainLsc",list,"min"=>0,"max"=>6000)
  make_figure("Ps",list,"min"=>90000,"max"=>110000)
  make_figure("PrcWtr",list,"min"=>0,"max"=>50)
end  

DCL.grcls
rename_img_file(list,__FILE__)
