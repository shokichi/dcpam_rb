#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# アルベドとH2O
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_omega.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math


def draw_scatter(dir,name,hash={})
  albedo = gpopen( dir+"local_Albedo.nc","Albedo").cut("lat"=>-30..30)
  h2o = gpopen( dir+"H2OLiqIntP.nc").cut("lat"=>-30..30)
  return if albedo.nil? or h2o.nil?


  if defined?(HrInDay) and !HrInDay.nil? then
    hr_in_day = HrInDay
  else
    hr_in_day = 24 / Utiles_spe.omega_ratio(name)
  end
  nlon = albedo.axis(0).length
  
  skip = 6*24*8
  (albedo.axis("time").length/skip).times{ |t|
    time = t*skip 
    h = h2o[false,time..time]
    h = h/cos_ang(h,hr_in_day)
    x_coord = local_time(h/cos_ang(h,hr_in_day),hr_in_day)
    x_coord = x_coord[nlon/4+1..nlon*3/4-2,false]
#    y_coord = albedo[nlon/4+1..nlon*3/4-2,true,time..time]
    y_coord = albedo[false,time..time]
    hash = {'title'=> "Albedo & H2O"+" "+name,
                 'annotate'=>false, }.merge(hash)
    if t == 0 then
      GGraph.scatter(x_coord,y_coord,true,hash)
    else  
      GGraph.scatter(x_coord,y_coord,false)   
    end
  }
end

def cos_ang(gp,hr_in_day) 
  # 太陽天頂角の計算
  time = gp.axis("time").to_gphys
  lon = gp.axis("lon").to_gphys if gp.axnames.include?("lon")
  lat = gp.axis("lat").to_gphys if gp.axnames.include?("lat")
  # 太陽直下点の計算
  time = Utiles_spe.min2day(gp,hr_in_day).axis("time").to_gphys
  slon = (time - time.to_i)*360
  slon = UNumeric[slon[0].val,"degree"]    # 太陽直下点経度
  slon = UNumeric[0,"degree"]    # 太陽直下点経度

  ang = gp[false,0].copy
  ang[false] = 1.0
  ang.units = "1"
  ang = ang*((ang.axis("lon").to_gphys+slon)*PI/180.0).cos
  ang = ang*(ang.axis("lat").to_gphys*PI/180.0).cos
  return ang + 1e-14
end


opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-h VAL","--hr_in_day=VAL") {|hr_in_day| HrInDay = hr_in_day.to_i}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}
opt.parse!(ARGV)

IWS = 1 if !defined?(IWS)
# DCL set
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)


list = Utiles_spe::Explist.new(ARGV[0])
HrInDay = 24 if list.id.include?("coriolis")
GGraph.set_fig('window'=>[0,200,0,1])
list.dir.each_index{ |n| draw_scatter(list.dir[n],list.name[n])}

DCL.grcls
rename_img_file(list.id,__FILE__)
