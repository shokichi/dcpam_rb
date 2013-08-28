#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 緯度分布の図を作成
# 

require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/make_figure.rb")
include MKfig
include NumRu

# 
list = Utiles_spe::Explist.new(ARGV[0])

# DCL open
# DCL open
if ARGV.index("-ps")
  iws = 2
elsif ARGV.index("-png")
  DCL::swlset('lwnd',false)
  iws = 4
else
  iws = 1
end

# DCL set
DCL.gropn(iws)
# DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
GGraph.set_fig('window'=>[-90,90,nil,nil])


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


DCL.grcls

img_lg = list.id+"_lat"
if ARGV.index("-ps") 
  File.rename("dcl.ps","#{img_lg}.ps")
elsif ARGV.index("-png")
  Dir.glob("dcl_*.png").each{ |filename|
    File.rename(filename,filename.sub("dcl",img_lg)) }
end
