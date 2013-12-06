#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 熱フラックスの南北分布
#
require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_omega.rb")
require 'optparse'
include MKfig
include Utiles_spe
include NumRu
include Math

def heart_flux(dir)
  # file open
  osr = gpopen dir + "OSRA.nc"
  olr = gpopen dir + "OLRA.nc"

  osr = cut_and_mean(osr)
  olr = cut_and_mean(olr)

  result = calc_heat_flux(osr,olr)  
  return result 
end

def calc_heat_flux(gsw,glw)
  lat = gsw.axis('lat').to_gphys
#  time = gsw.axis('time')

  # 半整数レベルの緯度を求める
  r_lat = VArray.new(NArray.sfloat(lat.length - 1))
  for i in 0..lat.length - 2
    r_lat[i] = (lat[i].val + lat[i+1].val)/2
  end
  r_lat.name = 'lat'
  # データを(lat[j]+lat[j+1])/2上に置く
  rlat = Axis.new
  rlat.set_pos(r_lat)
  flux_na = NArray.sfloat(r_lat.length)
  flux = GPhys.new(Grid.new(rlat),VArray.new(flux_na))   
  r_lat = r_lat * PI / 180


  alph = -(gsw + glw ) * 2.0 * PI * RPlanet * RPlanet  

  # 赤道から極に向かって積分する
  # 北半球
  i = lat.length/2

  flux[i] = alph[i].val * sin(r_lat[i].val)  
  for i in lat.length/2+1..lat.length-2
    flux[i] = flux[i-1].val + alph[i].val * \
              (sin(r_lat[i].val) - sin(r_lat[i-1].val))
  end

  # 南半球
  i = lat.length/2-2
  flux[i] = alph[i+1].val * sin(r_lat[i].val)
  for i in 0..lat.length/2-3
    i = lat.length/2-3 - i
    flux[i] = flux[i+1].val + alph[i+1].val * \
              (sin(r_lat[i].val) - sin(r_lat[i+1].val))  
  end
  flux.long_name = 'flux'
  flux.units = 'W'

  return flux
end

def cut_and_mean(gp)
  gp = gp.mean("time") if gp.axnames.include?("time")
  gp = gp.mean("lon") if gp.axnames.include?("lon")
  return gp 
end


opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("--max=Num") {|max| Max = max.to_f}
opt.on("--min=Num") {|min| Min = min.to_f}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}

opt.parse!(ARGV)
varname = VarName if defined?(VarName)
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
data=[]  

GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
GGraph.set_fig('window'=>[-90,90,nil,nil])

list.dir.each{|dir| data << heart_flux(dir)}
figopt = set_figopt
Omega.lat_fig2(data,list,figopt)
DCL.grcls
rename_img_file(list,__FILE__)

=begin
# 南極から積分する場合
  i = 0
  flux[i] = alph[i].val * ( sin(r_lat[i].val) + 1 ) 
  for i in 1..lat.length/2-2
#    i = lat.length/2-3 - i
    flux[i] = flux[i-1].val - alph[i].val * \
              (-sin(r_lat[i].val) + sin(r_lat[i-1].val))  
  end
  i = lat.length/2-2
#  flux[i] = flux[i-1] - alph[i].val * sin(r_lat[i-1].val)
=end
