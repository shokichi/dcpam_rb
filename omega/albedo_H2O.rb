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
  albedo = gpopen( dir+"local_Albedo.nc","Albedo").cut_rank_conserving("lat"=>0)
  h2o = gpopen( dir+"H2OLiqIntP.nc").cut_rank_conserving("lat"=>0)
  return if albedo.nil? or h2o.nil?

  if defined?(HrInDay) and !HrInDay.nil? then
    hr_in_day = HrInDay
  else
    hr_in_day = 24 / Utiles_spe.omega_ratio(name)
  end

  nlon = h2o.axis(0).length
  
  skip = 6*24
  (albedo.axis("time").length/skip).times{ |t|
    time = t*skip 
    h = h2o[false,time..time]
    h = local_time(h,hr_in_day)
    x_coord = h/cos_ang(h,hr_in_day)
    x_coord = x_coord[nlon/4+1..nlon*3/4-2,false]
#    y_coord = albedo[nlon/4+1..nlon*3/4-2,true,time..time]
    y_coord = albedo[false,time..time]

    hash = {'title'=> "Albedo & H2O"+" "+name,
                 'annotate'=>false,"type"=>1 }.merge(hash)
    if t == 0 then
      GGraph.scatter(x_coord,y_coord,true,hash)
    else  
      GGraph.scatter(x_coord,y_coord,false,"type"=>1)   
    end
  }
end

def draw_scatter2(dir,name,hash={})
  albedo = gpopen( dir+"local_Albedo.nc","Albedo").cut_rank_conserving("lat"=>0)
  h2o = gpopen( dir+"H2OLiqIntP.nc").cut_rank_conserving("lat"=>0)
  return if albedo.nil? or h2o.nil?

  if defined?(HrInDay) and !HrInDay.nil? then
    hr_in_day = HrInDay
  else
    hr_in_day = 24 / Utiles_spe.omega_ratio(name)
  end

  nlon = h2o.axis(0).length
  
  skip = 6
  (albedo.axis("time").length/skip).times{ |t|
    time = t*skip 
    x_coord = h2o[false,time..time]
    h = local_time(h,hr_in_day)
#    x_coord = h/cos_ang(h,hr_in_day)
    x_coord = x_coord[nlon/2..nlon/2,false]
    lon = x_coord.axis("lon").to_gphys.val.to_f
#    y_coord = albedo[nlon/4+1..nlon*3/4-2,true,time..time]
    y_coord = albedo[false,time..time].cut("lon"=>lon)

    hash = {'title'=> "Albedo & H2O"+" "+name,
                 'annotate'=>false,"type"=>1 }.merge(hash)
    if t == 0 then
      GGraph.scatter(x_coord,y_coord,true,hash)
    else  
      GGraph.scatter(x_coord,y_coord,false,"type"=>1)   
    end
  }
end

# option
Opt = OptCharge::OptCharge.new
Opt.set
list = Utiles_spe::Explist.new(ARGV[0])
IWS = get_iws
set_dcl(14)

HrInDay = 24 if list.id.include?("coriolis")
GGraph.set_fig('window'=>[0,2,0,1])
list.dir.each_index{ |n| 
  draw_scatter(list.dir[n],list.name[n],set_figopt)
  print_identifier(n)
}

DCL.grcls
rename_img_file(list.id,__FILE__)
