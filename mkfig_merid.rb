#!/usr/bin/ruby
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
clrmp = 14  # カラーマップ
DCL::swlset('lwnd',false) if IWS==4
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
# DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(0.9) # 文字の大きさ
  
GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
GGraph.set_fig('window'=>[-90,90,nil,nil])

if !varname.nil? then
  figopt = set_figopt
  merid_fig(varname,list,figopt)
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

rename_img_file(list,__FILE__)
