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

opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-h VAL","--hr_in_day=VAL") {|hr_in_day| HrInDay = hr_in_day.to_i}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}


def draw_scatter(dir,name,hash={})
  albedo = gpopen list.dir+"Albedo.nc"
  h2o = gpopen list.dir+"H2O.nc"
  albedo = cut_and_mean(albedo)
  h2o = cut_and_mean(h2o)
  

  if defined?(HrInDay) and !HrInDay.nil? then
    hr_in_day = HrInDay
  else
    hr_in_day = 24 / Utiles_spe.omega_ratio(name)
  end

  skip = 6*6
  (time.length/skip).times{ |t|
    time = t*skip 
    x_coord = albedo[false,time]
    y_coord = h2o[false,time]*cos_ang(h2o[false,time..time],hr_in_day)
    if t == 0
      GGraph.scatter(x_coord,y_coord,true,hash) 
    else  
      GGraph.scatter(x_coord,y_coord,false,hash)   
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
      
  # 大気上端下向きのSW
  ang = gp[false,0].copy
  ang[false] = 1.0
  ang.units = "1"
  ang = ang*((ang.axis("lon").to_gphys+slon)*PI/180.0).cos
  ang = ang*(ang.axis("lat").to_gphys*PI/180.0).cos
  return ang
end

def cut_and_mean(gp)
  return gp
end


list = Utiles_spe::Explist.new(ARGV[0])
HrInDay = 24 if list.id.include?("coriolis")
list.dir.each_index{ |n| draw_scatter(dir[n],name[n])}
