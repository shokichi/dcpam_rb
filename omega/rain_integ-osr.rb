#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 降水量と積算太陽放射
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_omega.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math

def intg_lon(gp)
  intg = osr.copy
  (gp.axis(0).length-1).times do |n|
    intg[n+1,false] = intg[n,false] + osr[n+1,false]
  end
  return intg
end

def rain_osr(dir)
  rain = gpopen dir + "Rain.nc"
  osr = gpopen dir + "OSRA.nc"
  lat = 0
  lat = Lat if defined? Lat
  intg = intg_lon(osr).cut("lat"=>lat).val.to_a
  result = Utiles_spe.array2gp(intg,rain.cut("lat"=>lat).val.to_a)
  result.name = rain.name
  result.long_name = rain.long_name
  return result
end

def fig_rain_intosr(list,figopt={})
  lc = 23
  vx = 0.82
  vy = 0.8
  list.dir.each_index do |n|
    gp = rain_osr(dir[n])

    # 描画
    vy = vy - 0.025
    if n == 0 then
      lc = 13 if list.ref.nil?
      fig_opt = {'index'=>lc,'legend'=>false,'annotate'=>false}
      GGraph.line( gp ,true ,fig_opt.merge(hash))
      DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
    elsif n == list.refnum
      lc_ref = 13
      fig_opt = {'index'=>lc_ref}      
      GGraph.line( gp ,false ,fig_opt.merge(hash))
      DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc_ref)     
    else
      lc = lc + 10
      fig_opt = {'index'=>lc}      
      GGraph.line( gp ,false ,fig_opt.merge(hash))
      DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
    end 
  end
end

opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-h VAL","--hr_in_day=VAL") {|hr_in_day| HrInDay = hr_in_day.to_i}
opt.on("--lat=Lat") {|lat| Lat = lat.to_f}
opt.on("--max=max") {|max| Max = max.to_f}
opt.on("--min=min") {|min| Min = min.to_f}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}
opt.parse!(ARGV)

list = Utiles_spe::Explist.new(ARGV[0])
IWS = 1 if !defined?(IWS) or IWS.nil?

# DCL set
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

figopt = set_figopt
fig_rain_intosr(list,figopt)

DCL.grcls
rename_img_file("omega",__FILE__)
