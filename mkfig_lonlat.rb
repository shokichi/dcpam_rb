#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# standerd figure
# No.4 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
require 'optparse'
include MKfig
include NumRu



#
opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-n VAR","--name=VAR") {|name| VarName = name}
opt.on("-o OPT","--figopt=OPT") {|hash| Figopt = hash}
opt.parse!(ARGV)
varname = VarName if defined?(VarName)
list = Utiles_spe::Explist.new(ARGV[0])

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
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(iws)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

if defined?(varname) then
  Figopt ||= {}
  lonlat("varname",list,Figopt)
else
  lonlat("OSRA",list,"min"=>-1200,"max"=>0,"nlev"=>20,"clr_min"=>99,"clr_max"=>56)
  lonlat("OLRA",list,"min"=>0,"max"=>300,"nlev"=>20,"clr_min"=>56,"clr_max"=>13)
  lonlat("EvapA",list,"max"=>1000,"clr_min"=>56,"clr_max"=>13)
  lonlat("SensA",list,"max"=>200,"nlev"=>20,"clr_min"=>56,"clr_max"=>13)
  lonlat("SSRA",list,"min"=>-1000,"max"=>0,"clr_min"=>99,"clr_max"=>56)
  lonlat("SLRA",list,"min"=>0,"max"=>200,"nlev"=>20,"clr_min"=>56,"clr_max"=>13)
  lonlat("Rain",list,"min"=>0,"max"=>1000,"nlev"=>20)
  lonlat("RainCumulus",list,"min"=>0,"max"=>500)
  lonlat("RainLsc",list,"min"=>0,"max"=>500,"nlev"=>20)
  lonlat("SurfTemp",list,"min"=>220,"max"=>360)
  lonlat("Temp",list,"min"=>220,"max"=>320)
  lonlat("RH",list,"min"=>0,"max"=>100)
  lonlat("H2OLiq",list,"min"=>0,"max"=>0.1)
  lonlat("PrcWtr",list,"min"=>0,"max"=>100,"nlev"=>20)      
  lonlat("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
  lonlat("V",list,"min"=>-10,"max"=>10)      
end  
DCL.grcls

img_lg = list.id+"_lonlat"
if ARGV.index("-ps") 
  File.rename("dcl.ps","#{img_lg}.ps")
elsif ARGV.index("-png")
  Dir.glob("dcl_*.png").each{ |filename|
    File.rename(filename,filename.sub("dcl",img_lg)) }
end
