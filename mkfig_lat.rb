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
IWS = 2 if Opt.charge[:ps] || Opt.charge[:eps]
IWS = 4 if Opt.charge[:png]
IWS = 1 if !defined? IWS

list = Utiles_spe::Explist.new(ARGV[0])

# DCL set
DCL::swlset('lwnd',false) if IWS==4
DCL.gropn(IWS)
# DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
GGraph.set_fig('window'=>[-90,90,nil,nil])

if !Opt.charge[:varname].nil? then
  lat_fig(Opt.charge[:varname],list,set_figopt)
else
  lat_fig("OSRA",list,"min"=>0,"max"=>-320)
  lat_fig("OLRA",list,"min"=>0,"max"=>320)
  lat_fig("EvapA",list,"min"=>-20,"max"=>300)
  lat_fig("SensA",list,"min"=>-20,"max"=>300)
  lat_fig("SSRA",list,"min"=>20,"max"=>-300)
  lat_fig("SLRA",list,"min"=>-20,"max"=>300)
  lat_fig("Temp",list,"min"=>200,"max"=>300)
  lat_fig("SurfTemp",list,"min"=>200,"max"=>300)
  lat_fig("Rain",list,"min"=>0,"max"=>6000)
  lat_fig("RainCumulus",list,"min"=>0,"max"=>6000)
  lat_fig("RainLsc",list,"min"=>0,"max"=>6000)
  lat_fig("Ps",list,"min"=>90000,"max"=>110000)
  lat_fig("PrcWtr",list,"min"=>0,"max"=>50)
end  

DCL.grcls
rename_img_file(list,__FILE__)
