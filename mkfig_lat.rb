#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 緯度分布の図を作成
# 

require "numru/ggraph"
require 'optparse'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/make_figure.rb")
include MKfig
include NumRu

# option
opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-n VAR","--name=VAR") {|name| VarName = name}
opt.on("-o OPT","--figopt=OPT") {|hash| Figopt = hash}
opt.on("--ps") { IWS = 1}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}
opt.parse!(ARGV) 

list = Utiles_spe::Explist.new(ARGV[0])
varname = VarName if defined?(VarName)
IWS = 1 if !defined?(IWS) or IWS.nil?

# DCL set
DCL.gropn(IWS)
# DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
GGraph.set_fig('window'=>[-90,90,nil,nil])

if !varname.nil? then
  Figopt ||= {}
  lat_fig("varname",list,Figopt)
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

img_lg = list.id+File.basename(__FILE__,"rb").sub("mkfig","")
if IWS == 2 
  File.rename("dcl.ps","#{img_lg}.ps")
elsif IWS == 4
  Dir.glob("dcl_*.png").each{ |filename|
    File.rename(filename,filename.sub("dcl",img_lg)) }
end
