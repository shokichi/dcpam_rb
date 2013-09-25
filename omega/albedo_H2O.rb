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
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}


def draw_scatter(prc,qvap,hash={})
  albedo = gpopen list.dir+"Albedo.nc"
  h2o = gpopen list.dir+"H2O.nc"
  albedo = cut_and_mean(albedo)
  h2o = cut_and_mean(h2o)

  skip = 6

  time.length/skip.times{ |t|
    GGraph.scatter albedo[false,t*skip],h2o[false,t*skip],true,hash  
  }
end

def ang_slr_znt(gp)
  # 太陽天頂角の計算
  lon = gp.axis("lon").to_gphys if gp.axnames.include?("lon")
  lat = gp.axis("lat").to_gphys if gp.axnames.include?("lat")
  time = gp.axis("time").to_gphys if gp.axnames.include?("time")
  cos_phi = lon.cos * lat.sin
end

def cut_and_mean(gp)
  return gp
end

list.dir.each{ |dir| draw_scatter(get_prcwtr(dir),get_satQVap(dir))}
