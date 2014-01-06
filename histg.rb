#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# histogram
# ヒストグラムの作成 
#

require 'numru/ganalysis'
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
include MKfig
include NumRu
include Math

def hist_fig(data_name,list,opt={})
  list.dir.each_index do |n|
    gp = gpopen list.dir[n] + data_name+".nc"
    next if gp.nil?
    gp = gp.wm2mmhr if gp.name.include? "Rain"
    gp = gp.cut("sig"=>1) if gp.axnames.include? "sig"
    hr_in_day = Utiles_spe.omega_ratio(list.name[n])
    gp = local_time(gp.cut("lat"=>0),hr_in_day)  #
    gh = histogram_lon(gp,opt)
    draw_fig(gh,list.name[n])
  end
end

def draw_fig(gp,legend,hash={})
#  xcoord = gp.axis(0).to_gphys.val
#  xmax = (xcoord[1]-xcoord[0])*xcoord.length
#  GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
  fig_opt = {'title'=>gp.long_name + " " + legend,
    'annotate'=>false,
    'color_bar'=>true,
    'nlev'=>30,
    'log'=>3}.merge(hash)
  GGraph.set_fig('window'=>[0,nil,nil,nil])
  GGraph.tone(gp,true,fig_opt)
end

def histogram_dev_time(gphys,range)
  gh = 0
  GPhys.each_along_dims(gphys,"time") do |gp|
    gh = gh + gp.histogram(range)
  end
  gh = gh/gphys.total
  return gh
end

def histogram_lon(gphys,range)
  puts "Array size is too large" if gphys[0,false].length > 100000000
  gha = []
  lon = gphys.axis("lon")
  lon.to_gphys.val.to_a.each do |lon|
    gp = gphys.cut_rank_conserving("lon"=>lon)
    gha << (gp.histogram(range)+1)/gp.total
  end
  tmp = gha[0]

  gh_na = NArray.sfloat(lon.length,tmp.axis(0).length)
  grid = Grid.new(lon,tmp.axis(0))
  gh = GPhys.new(grid,VArray.new(gh_na))

  lon.to_gphys.val.to_a.each_index do |n|
    gh[n,true] = gha[n][false].val
  end
  gh.long_name = gphys.long_name  
  gh.name = gphys.name
  gh.units = gphys.units
  return gh
end

# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set

list = Utiles_spe::Explist.new(ARGV[0])
IWS = get_iws

set_dcl(14)

hist_fig("H2OLiqIntP",list,"min"=>0,"max"=>30,"nbins"=>300)
#hist_fig("RH",list,"min"=>0,"max"=>120,"nbins"=>120)

DCL.grcls
rename_img_file(list.id,__FILE__)
