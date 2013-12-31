#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# histogram
# ヒストグラムの作成 
#

require 'numru/ganalysis'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/make_fig.rb")
include MKfig
include NumRu
include Math

def hist_fig(data_name,list,opt={})
  list.dir.each_index do |n|
    gp = gpopen list.dir[n] + data_name+".nc"
    next if gp.nil?
    gp = gp.wm2mmhr if gp.name.include? "Rain"
    gp = gp.cut("sig"=>1) if gp.axnames.include? "sig"
    gp = local_time(gp.cut("lat"=>0),hr_in_day)
    gh = histogram_lon(gp,opt)
    draw_fig(gh,list.name[n])
  end
end

def draw_fig(gh,legend,hash={})
  xcoord = gp.axis(0).to_gphys.val
  xmax = (xcoord[1]-xcoord[0])*xcoord.length
  GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
  fig_opt = {'title'=>gp.long_name + " " + legend,
    'annotate'=>false,
    'color_bar'=>true}.merge(hash)
  GGraph.set_fig('window'=>[0,xmax,nil,nil])
  GGraph.tone gh,true,fig_opt
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
  gh = []
  GPhys.each_along_dims(gphys,"lon") do |gp|
    gh << gp.histogram(range)/gp.total
  end
  result = GPhys.join(gh)
  return result
end

# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set

list = Utiles_spe::Explist.new(ARGV[0])
IWS = 2 if Opt.charge[:ps] || Opt.charge[:eps]
IWS = 4 if Opt.charge[:png]
IWS = 1 if !defined? IWS

clrmp = 14  # カラーマップ
DCL::swlset('lwnd',false) if IWS==4
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

hist_fig("H2OLiqIntP",list,"min"=>0,"max"=>30,"nbins"=>300)
#hist_fig("RH",list,"min"=>0,"max"=>120,"nbins"=>120)

DCL.grcls
rename_img_file(list.id,__FILE__)
