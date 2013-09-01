#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# make standerd figure 
# 子午面断面
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
opt.parse!(ARGV)
list = Utiles_spe::Explist.new(ARGV[0])
varname = VarName if defined?(VarName)

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
# DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(0.9) # 文字の大きさ
  
GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
GGraph.set_fig('window'=>[-90,90,nil,nil])

if defined?(varname) then
  Figopt ||= {}
  merid_fig("varname",list,Figopt)
else
  merid_fig('Temp',list,"min"=>120,"max"=>320,"interval"=>10)
  merid_fig('U',list,"min"=>-80,"max"=>80,"interval"=>5)
  merid_fig('V',list,"min"=>-8,"max"=>8)
  merid_fig('RH',list,"min"=>0,"max"=>100)
  merid_fig('SigDot',list,"min"=>-1.5e-6,"max"=>1.5e-6)
  merid_fig('QVap',list,"min"=>0,"max"=>0.015)
  merid_fig('H2OLiq',list,"min"=>0,"max"=>5e-5)
  merid_fig('Strm',list,"min"=>-50,"max"=>50,"nlev"=>20)
end

DCL.grcls


img_lg = list.id+"_merid"
if ARGV.index("-ps") 
  File.rename("dcl.ps","#{img_lg}.ps")
elsif ARGV.index("-png")
  Dir.glob("dcl_*.png").each{ |filename|
    File.rename(filename,filename.sub("dcl",img_lg)) }
end
